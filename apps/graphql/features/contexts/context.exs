defmodule GraphQL.Features.Context do
  use WhiteBread.Context
  use Phoenix.ConnTest

  import Core.Expectations.Mithril, only: [get_client_type_name: 1]
  import Core.Factories, only: [insert: 3, insert_list: 3]

  alias Absinthe.Relay.Node
  alias Core.{Repo, PRMRepo, EventManagerRepo}
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.LegalEntities.LegalEntity
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias Mox
  alias Phoenix.ConnTest

  @consumer_id_header "x-consumer-id"
  @consumer_metadata_header "x-consumer-metadata"
  @drfo_header "drfo"

  @endpoint GraphQLWeb.Endpoint

  @graphql_path "/graphql"

  scenario_starting_state(fn _ ->
    :ok = Sandbox.checkout(Repo)
    :ok = Sandbox.checkout(PRMRepo)
    :ok = Sandbox.checkout(EventManagerRepo)

    Mox.Server.verify_on_exit(self())

    %{conn: ConnTest.build_conn()}
  end)

  scenario_finalize(fn status, state ->
    Sandbox.checkin(Repo)
    Sandbox.checkin(PRMRepo)
    Sandbox.checkin(EventManagerRepo)

    with {:ok, _} <- status, do: Mox.verify!()
    Mox.Server.exit(self())

    state
  end)

  given_(~r/^my scope is "(?<scope>[^"]+)"$/, fn %{conn: conn}, %{scope: scope} ->
    {:ok, %{conn: put_scope(conn, scope)}}
  end)

  given_(~r/^my client type is "(?<name>[^"]+)"$/, fn %{conn: conn}, %{name: name} ->
    get_client_type_name(name)

    {:ok, %{conn: put_client_id(conn)}}
  end)

  given_(~r/^my client ID is "(?<id>[^"]+)"$/, fn %{conn: conn}, %{id: id} ->
    {:ok, %{conn: put_client_id(conn, id)}}
  end)

  given_(
    ~r/^there are (?<count>\d+) capitation contract requests exist$/,
    fn state, %{count: count} ->
      count = String.to_integer(count)
      insert_list(count, :il, :capitation_contract_request)

      {:ok, state}
    end
  )

  given_(
    ~r/^the following capitation contract requests exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(CapitationContractRequest, row)
        insert(:il, :capitation_contract_request, attrs)
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following legal entities exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(LegalEntity, row)
        insert(:prm, :legal_entity, attrs)
      end

      {:ok, state}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests$/,
    fn %{conn: conn}, %{count: count} ->
      query = """
        query ListCapitationContractRequests($first: Int!) {
          capitationContractRequests(first: $first) {
            nodes {
              id
            }
          }
        }
      """

      variables = %{first: String.to_integer(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) is "(?<value>[^"]+)"$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
      query = """
        query ListCapitationContractRequestsWithFilter(
          $first: Int!
          $filter: CapitationContractRequestFilter!
        ) {
          capitationContractRequests(first: $first, filter: $filter) {
            nodes {
              #{field}
            }
          }
        }
      """

      variables = %{
        first: String.to_integer(count),
        filter: filter_argument(field, value)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests sorted by "(?<field>[^"]+)" in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
      query = """
        query ListCapitationContractRequestsWithOrderBy(
          $first: Int!
          $order_by: CapitationContractRequestOrderBy!
        ) {
          capitationContractRequests(first: $first, order_by: $order_by) {
            nodes {
              #{field}
            }
          }
        }
      """

      variables = %{
        first: String.to_integer(count),
        order_by: order_by_argument(field, direction)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request capitation contract request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id} ->
      query = """
        query GetCapitationContractRequestQuery($id: ID!) {
          capitationContractRequest(id: $id) {
            databaseId
          }
        }
      """

      variables = %{
        id: Node.to_global_id("CapitationContractRequest", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data capitationContractRequest))

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  then_("no errors should be returned", fn %{resp_body: resp_body} = state ->
    refute resp_body["errors"]

    {:ok, state}
  end)

  then_(
    ~r/^the "(?<code>[^"]+)" error should be returned$/,
    fn %{resp_body: resp_body} = state, %{code: code} ->
      assert Enum.any?(
               resp_body["errors"],
               fn error -> %{"extensions" => %{"code" => ^code}} = error end
             )

      {:ok, state}
    end
  )

  then_(
    ~r/^I should receive collection with (?<count>\d+) items?$/,
    fn %{resp_entities: resp_entities} = state, %{count: count} ->
      assert resp_entities
      assert String.to_integer(count) == length(resp_entities)

      {:ok, state}
    end
  )

  then_(
    ~r/^I should not receive any collection items$/,
    fn %{resp_entities: resp_entities} = state ->
      refute resp_entities

      {:ok, state}
    end
  )

  then_(
    ~r/^I should receive requested item$/,
    fn %{resp_entity: resp_entity} = state ->
      assert resp_entity

      {:ok, state}
    end
  )

  then_(
    ~r/^I should not receive requested item$/,
    fn %{resp_entity: resp_entity} = state ->
      refute resp_entity

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<field>[\w_]+) of the first item in the collection should be "(?<value>[^"]+)"$/,
    fn %{resp_entities: resp_entities} = state, %{field: field, value: value} ->
      resp_value =
        resp_entities
        |> hd()
        |> Map.get(field)
        |> to_string()

      assert value = resp_value

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<field>[\w_]+) of the requested item should be "(?<value>[^"]+)"$/,
    fn %{resp_entity: resp_entity} = state, %{field: field, value: value} ->
      resp_value =
        resp_entity
        |> Map.get(field)
        |> to_string()

      assert value = resp_value

      {:ok, state}
    end
  )

  def put_scope(conn, scope), do: put_req_header(conn, @endpoint.scope_header(), scope)

  def put_consumer_id(conn, id \\ UUID.generate()), do: put_req_header(conn, @consumer_id_header, id)

  def put_drfo(conn, drfo \\ "002233445566"), do: put_req_header(conn, @drfo_header, drfo)

  def put_client_id(conn, id \\ UUID.generate()) do
    metadata = Jason.encode!(%{"client_id" => id})
    put_req_header(conn, @consumer_metadata_header, metadata)
  end

  def post_query(conn, query, variables \\ %{}) do
    post(conn, @graphql_path, %{query: query, variables: variables})
  end

  def prepare_attrs(queryable, attrs) when is_map(attrs), do: prepare_attrs(queryable, Map.to_list(attrs))

  def prepare_attrs(_, []), do: []

  def prepare_attrs(queryable, [{field, value} | tail]) do
    with field <- prepare_field(field),
         {:ok, value} <- prepare_value(queryable, field, value) do
      [{field, value} | prepare_attrs(queryable, tail)]
    else
      _ -> raise "Unable to parse \"#{value}\" as value for field \"#{field}\"."
    end
  end

  defp prepare_field(:databaseId), do: :id

  defp prepare_field(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> prepare_field()
    |> String.to_atom()
  end

  defp prepare_field(key), do: Macro.underscore(key)

  defp prepare_value(queryable, field, value) do
    case queryable.__schema__(:type, field) do
      :date -> Date.from_iso8601(value)
      :datetime -> DateTime.from_iso8601(value)
      :naive_datetime -> NaiveDateTime.from_iso8601(value)
      _ -> {:ok, value}
    end
  end

  def filter_argument(field, value), do: %{field => value}

  def order_by_argument(field, "ascending"), do: order_by_argument(field, "ASC")
  def order_by_argument(field, "descending"), do: order_by_argument(field, "DESC")

  def order_by_argument(field, direction) do
    field =
      field
      |> Macro.underscore()
      |> String.upcase()

    Enum.join([field, direction], "_")
  end
end
