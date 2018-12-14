defmodule GraphQL.Features.Context do
  use WhiteBread.Context
  use Phoenix.ConnTest

  import Core.Expectations.Mithril, only: [get_client_type_name: 1]
  import Core.Factories, only: [insert: 3, insert_list: 3]

  alias Absinthe.Relay.Node
  alias Core.{Repo, PRMRepo, EventManagerRepo}
  alias Core.ContractRequests.{CapitationContractRequest, ReimbursementContractRequest}
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Parties.Party
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
    ~r/^there are (?<count>\d+) capitation contracts exist$/,
    fn state, %{count: count} ->
      count = String.to_integer(count)
      insert_list(count, :prm, :capitation_contract)

      {:ok, state}
    end
  )

  given_(
    ~r/^there are (?<count>\d+) capitation contract requests exist$/,
    fn state, %{count: count} ->
      count = Jason.decode!(count)
      insert_list(count, :il, :capitation_contract_request)

      {:ok, state}
    end
  )

  given_(
    ~r/^there are (?<count>\d+) reimbursement contracts exist$/,
    fn state, %{count: count} ->
      count = String.to_integer(count)
      insert_list(count, :prm, :reimbursement_contract)

      {:ok, state}
    end
  )

  given_(
    ~r/^there are (?<count>\d+) reimbursement contract requests exist$/,
    fn state, %{count: count} ->
      count = Jason.decode!(count)
      insert_list(count, :il, :reimbursement_contract_request)

      {:ok, state}
    end
  )

  given_(
    ~r/^there are (?<count>\d+) medical programs exist$/,
    fn state, %{count: count} ->
      count = Jason.decode!(count)
      insert_list(count, :prm, :medical_program)

      {:ok, state}
    end
  )

  given_(
    ~r/^there are (?<count>\d+) employees exist$/,
    fn state, %{count: count} ->
      count = Jason.decode!(count)
      insert_list(count, :prm, :employee)

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
    ~r/^the following reimbursement contract requests exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(ReimbursementContractRequest, row)
        insert(:il, :reimbursement_contract_request, attrs)
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following employees exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(Employee, row)
        # FIXME: There are should be better way to set party_id foreign key for employee
        insert(:prm, :employee, [{:party, nil} | attrs])
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

  given_(
    ~r/^the following medical programs exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(MedicalProgram, row)
        insert(:prm, :medical_program, attrs)
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following parties exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(Party, row)
        insert(:prm, :party, attrs)
      end

      {:ok, state}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contracts$/,
    fn %{conn: conn}, %{count: count} ->
      query = """
        query ListCapitationContracts($first: Int!) {
          capitationContracts(first: $first) {
            nodes {
              id
              databaseId
            }
          }
        }
      """

      variables = %{first: Jason.decode!(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
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
              databaseId
            }
          }
        }
      """

      variables = %{first: Jason.decode!(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contracts$/,
    fn %{conn: conn}, %{count: count} ->
      query = """
        query ListReimbursementContracts($first: Int!) {
          reimbursementContracts(first: $first) {
            nodes {
              id
              databaseId
            }
          }
        }
      """

      variables = %{first: Jason.decode!(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contract requests$/,
    fn %{conn: conn}, %{count: count} ->
      query = """
        query ListReimbursementContractRequests($first: Int!) {
          reimbursementContractRequests(first: $first) {
            nodes {
              id
              databaseId
            }
          }
        }
      """

      variables = %{first: Jason.decode!(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medical programs$/,
    fn %{conn: conn}, %{count: count} ->
      query = """
        query ListMedicalPrograms($first: Int!) {
          medicalPrograms(first: $first) {
            nodes {
              id
              databaseId
            }
          }
        }
      """

      variables = %{first: Jason.decode!(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data medicalPrograms nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees$/,
    fn %{conn: conn}, %{count: count} ->
      query = """
        query ListEmployees($first: Int!) {
          employees(first: $first) {
            nodes {
              id
              databaseId
            }
          }
        }
      """

      variables = %{first: Jason.decode!(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
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
        first: Jason.decode!(count),
        filter: filter_argument(field, Jason.decode!(value))
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
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
      query = """
        query ListReimbursementContractRequestsWithFilter(
          $first: Int!
          $filter: ReimbursementContractRequestFilter!
        ) {
          reimbursementContractRequests(first: $first, filter: $filter) {
            nodes {
              #{field}
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument(field, Jason.decode!(value))
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medical programs where (?<field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
      query = """
        query ListMedicalProgramsWithFilter(
          $first: Int!
          $filter: MedicalProgramFilter!
        ) {
          medicalPrograms(first: $first, filter: $filter) {
            nodes {
              #{field}
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument(field, Jason.decode!(value))
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data medicalPrograms nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees where (?<field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
      query = """
        query ListEmployeesWithFilter(
          $first: Int!
          $filter: EmployeeFilter!
        ) {
          employees(first: $first, filter: $filter) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument(field, Jason.decode!(value))
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, field: field, value: value} ->
      query = """
        query ListCapitationContractRequestsWithAssocFilter(
          $first: Int!
          $filter: CapitationContractRequestFilter!
        ) {
          capitationContractRequests(first: $first, filter: $filter) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument(association_field, field, Jason.decode!(value))
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
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, field: field, value: value} ->
      query = """
        query ListReimbursementContractRequestsWithAssocFilter(
          $first: Int!
          $filter: ReimbursementContractRequestFilter!
        ) {
          reimbursementContractRequests(first: $first, filter: $filter) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument(association_field, field, Jason.decode!(value))
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, field: field, value: value} ->
      query = """
        query ListEmployeesWithAssocFilter(
          $first: Int!
          $filter: EmployeeFilter!
        ) {
          employees(first: $first, filter: $filter) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument(association_field, field, Jason.decode!(value))
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) of the (?<nested_association_field>\w+) nested in associated (?<association_field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, nested_association_field: nested_association_field, field: field, value: value} ->
      query = """
        query ListCapitationContractRequestsWithAssocFilter(
          $first: Int!
          $filter: CapitationContractRequestFilter!
        ) {
          capitationContractRequests(first: $first, filter: $filter) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument(association_field, nested_association_field, field, Jason.decode!(value))
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
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) of the (?<nested_association_field>\w+) nested in associated (?<association_field>\w+) is (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, nested_association_field: nested_association_field, field: field, value: value} ->
      query = """
        query ListReimbursementContractRequestsWithAssocFilter(
          $first: Int!
          $filter: ReimbursementContractRequestFilter!
        ) {
          reimbursementContractRequests(first: $first, filter: $filter) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument(association_field, nested_association_field, field, Jason.decode!(value))
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
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
        first: Jason.decode!(count),
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
    ~r/^I request first (?<count>\d+) reimbursement contract requests sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
      query = """
        query ListReimbursementContractRequestsWithOrderBy(
          $first: Int!
          $order_by: ReimbursementContractRequestOrderBy!
        ) {
          reimbursementContractRequests(first: $first, order_by: $order_by) {
            nodes {
              #{field}
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        order_by: order_by_argument(field, direction)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContractRequests nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medical programs sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
      query = """
        query ListMedicalProgramsWithOrderBy(
          $first: Int!
          $order_by: MedicalProgramOrderBy!
        ) {
          medicalPrograms(first: $first, order_by: $order_by) {
            nodes {
              #{field}
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        order_by: order_by_argument(field, direction)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data medicalPrograms nodes))

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
      query = """
        query ListEmployeesWithOrderBy(
          $first: Int!
          $order_by: EmployeeOrderBy!
        ) {
          employees(first: $first, order_by: $order_by) {
            nodes {
              #{field}
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        order_by: order_by_argument(field, direction)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

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

  when_(
    ~r/^I request reimbursement contract request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id} ->
      query = """
        query GetReimbursementContractRequestQuery($id: ID!) {
          reimbursementContractRequest(id: $id) {
            databaseId
          }
        }
      """

      variables = %{
        id: Node.to_global_id("ReimbursementContractRequest", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContractRequest))

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request employee where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id} ->
      query = """
        query GetEmployeeQuery($id: ID!) {
          employee(id: $id) {
            databaseId
          }
        }
      """

      variables = %{
        id: Node.to_global_id("Employee", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employee))

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the reimbursement contract request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{field: field, database_id: database_id} ->
      query = """
        query GetReimbursementContractRequestQuery($id: ID!) {
          reimbursementContractRequest(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("ReimbursementContractRequest", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContractRequest))

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the medical program where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{field: field, database_id: database_id} ->
      query = """
        query GetMedicalProgramQuery($id: ID!) {
          medicalProgram(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("MedicalProgram", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data medicalProgram))

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the employee where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{field: field, database_id: database_id} ->
      query = """
        query GetEmployeeQuery($id: ID!) {
          employee(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("Employee", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employee))

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the reimbursement contract request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{nested_field: nested_field, field: field, database_id: database_id} ->
      query = """
        query GetReimbursementContractRequestQuery($id: ID!) {
          reimbursementContractRequest(id: $id) {
            #{field} {
              #{nested_field}
            }
          }
        }
      """

      variables = %{
        id: Node.to_global_id("ReimbursementContractRequest", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContractRequest))

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the employee where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{nested_field: nested_field, field: field, database_id: database_id} ->
      query = """
        query GetEmployeeQuery($id: ID!) {
          employee(id: $id) {
            #{field} {
              #{nested_field}
            }
          }
        }
      """

      variables = %{
        id: Node.to_global_id("Employee", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employee))

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
    ~r/^the (?<field>\w+) of the first item in the collection should be (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{resp_entities: resp_entities} = state, %{field: field, value: value} ->
      expected_value = Jason.decode!(value)
      resp_value = hd(resp_entities)[field]

      assert expected_value == resp_value

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<field>\w+) in the (?<association_field>\w+) of the first item in the collection should be (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{resp_entities: resp_entities} = state, %{field: field, association_field: association_field, value: value} ->
      expected_value = Jason.decode!(value)
      resp_value = resp_entities |> hd() |> get_in([association_field, field])

      assert expected_value == resp_value

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<field>\w+) of the requested item should be (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{resp_entity: resp_entity} = state, %{field: field, value: value} ->
      expected_value = Jason.decode!(value)
      resp_value = resp_entity[field]

      assert expected_value == resp_value

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<nested_field>\w+) in the (?<field>\w+) of the requested item should be (?<value>(?:\d+|\w+|"[^"]+"))$/,
    fn %{resp_entity: resp_entity} = state, %{field: field, nested_field: nested_field, value: value} ->
      expected_value = Jason.decode!(value)
      resp_value = get_in(resp_entity, [field, nested_field])

      assert expected_value == resp_value

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

  def prepare_attrs(queryable, attrs) when is_map(attrs) do
    prepare_attrs(queryable, Map.to_list(attrs))
  end

  def prepare_attrs(_, []), do: []

  def prepare_attrs(queryable, [{field, value} | tail]) do
    with field <- prepare_field(field),
         {:ok, value} <- Jason.decode(value),
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
  def filter_argument(assoc, field, value), do: %{assoc => %{field => value}}
  def filter_argument(assoc, nested_assoc, field, value), do: %{assoc => %{nested_assoc => %{field => value}}}

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
