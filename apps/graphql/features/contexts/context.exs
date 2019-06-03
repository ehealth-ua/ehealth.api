defmodule GraphQL.Features.Context do
  use WhiteBread.Context
  use Phoenix.ConnTest

  import Core.Expectations.Man, only: [template: 0]
  import Core.Expectations.Mithril, only: [get_client_type_name: 1]
  import Core.Factories, only: [build: 2, build_list: 2, insert: 3, insert_list: 3]
  import Ecto.Query, only: [select: 3, where: 3]
  import Mox, only: [expect: 3, expect: 4, stub: 3]

  alias Absinthe.Relay.Node
  alias Core.{Repo, PRMRepo}
  alias Core.ContractRequests.{CapitationContractRequest, ReimbursementContractRequest}
  alias Core.Contracts.{CapitationContract, ReimbursementContract, ContractDivision, ContractEmployee}
  alias Core.Dictionaries.Dictionary
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.EmployeeRequests.EmployeeRequest
  alias Core.LegalEntities.{LegalEntity, RelatedLegalEntity}
  alias Core.Medications.{INNM, INNMDosage, Medication}
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Medications.Program, as: ProgramMedication
  alias Core.Parties.Party
  alias Core.PartyUsers.PartyUser
  alias Core.Services.{ProgramService, Service, ServiceGroup, ServicesGroups}
  alias Core.Uaddresses.{District, Region, Settlement}
  alias Core.Services.ServiceGroup
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias Jobs.LegalEntityMergeJob
  alias Mox
  alias Phoenix.ConnTest

  @consumer_id_header "x-consumer-id"
  @consumer_metadata_header "x-consumer-metadata"
  @drfo_header "drfo"

  @endpoint GraphQL.Endpoint

  @graphql_path "/graphql"

  scenario_starting_state(fn _ ->
    :ok = Sandbox.checkout(Repo)
    :ok = Sandbox.checkout(PRMRepo)

    Mox.Server.verify_on_exit(self())
    Mox.Server.set_mode(self(), :global)

    %{
      set_env_variables: [],
      existing: %{},
      conn: ConnTest.build_conn(),
      resp_body: nil,
      resp_entities: nil,
      resp_entity: nil
    }
  end)

  scenario_finalize(fn status, state ->
    Enum.each(state.set_env_variables, &System.delete_env/1)

    Sandbox.checkin(Repo)
    Sandbox.checkin(PRMRepo)

    with {:ok, _} <- status, do: Mox.verify!()
    Mox.Server.exit(self())

    state
  end)

  given_(
    ~r/^the environment variable "(?<name>[^"]+)" set to "(?<value>[^"]+)"$/,
    fn %{set_env_variables: set_env_variables} = state, %{name: name, value: value} ->
      System.put_env(name, value)

      {:ok, %{state | set_env_variables: [name | set_env_variables]}}
    end
  )

  given_(~r/^my scope is "(?<scope>[^"]+)"$/, fn %{conn: conn} = state, %{scope: scope} ->
    {:ok, %{state | conn: put_scope(conn, scope)}}
  end)

  given_(~r/^my consumer ID is "(?<id>[^"]+)"$/, fn %{conn: conn} = state, %{id: id} ->
    {:ok, %{state | conn: put_consumer_id(conn, id)}}
  end)

  given_(~r/^my client type is "(?<name>[^"]+)"$/, fn %{conn: conn} = state, %{name: name} ->
    get_client_type_name(name)

    {:ok, %{state | conn: put_client_id(conn)}}
  end)

  given_(~r/^my client ID is "(?<id>[^"]+)"$/, fn %{conn: conn} = state, %{id: id} ->
    {:ok, %{state | conn: put_client_id(conn, id)}}
  end)

  given_(
    ~r/^there are (?<count>\d+) (?<entity_name>(\w+\s?)+) exist$/,
    fn %{existing: existing} = state, %{count: count, entity_name: entity_name} ->
      count = Jason.decode!(count)
      entity_name = Inflex.singularize(entity_name)
      model = entity_name_to_model(entity_name)

      items =
        case entity_name_to_factory_args(entity_name) do
          {nil, factory_name} ->
            build_list(count, factory_name)

          {repo_name, factory_name} ->
            insert_list(count, repo_name, factory_name)
        end

      {:ok, %{state | existing: Map.put(existing, model, items)}}
    end
  )

  given_(
    ~r/^the following (?<entity_name>(\w+\s?)+) exist:$/,
    fn %{existing: existing} = state, %{entity_name: entity_name, table_data: table_data} ->
      entity_name = Inflex.singularize(entity_name)
      model = entity_name_to_model(entity_name)

      items =
        case entity_name_to_factory_args(entity_name) do
          {nil, factory_name} ->
            for row <- table_data do
              attrs = prepare_attrs(model, row)
              build(factory_name, attrs)
            end

          {repo_name, factory_name} ->
            for row <- table_data do
              attrs = prepare_attrs(model, row)
              insert(repo_name, factory_name, attrs)
            end
        end

      {:ok, %{state | existing: Map.put(existing, model, items)}}
    end
  )

  given_(
    ~r/^the following (?<entity_name>[\w\s]+) are associated with (?<assoc_entity_name>[\w\s]+) accordingly:$/,
    fn %{existing: existing} = state,
       %{entity_name: entity_name, assoc_entity_name: assoc_entity_name, table_data: table_data} ->
      entity_name = Inflex.singularize(entity_name)
      assoc_entity_name = Inflex.singularize(assoc_entity_name)

      model = entity_name_to_model(entity_name)
      assoc_model = entity_name_to_model(assoc_entity_name)
      assoc_items = existing[assoc_model]

      if length(table_data) != length(assoc_items) do
        raise "Items count should match with associated items count"
      end

      assoc_field =
        model.__schema__(:associations)
        |> Enum.map(&model.__schema__(:association, &1))
        |> Enum.find(fn
          %{related: related} -> assoc_model == related
          _ -> false
        end)
        |> Map.get(:field)

      items =
        case entity_name_to_factory_args(entity_name) do
          {nil, factory_name} ->
            for {row, assoc_item} <- Enum.zip(table_data, assoc_items) do
              attrs = prepare_attrs(model, row)
              build(factory_name, [{assoc_field, assoc_item} | attrs])
            end

          {repo_name, factory_name} ->
            for {row, assoc_item} <- Enum.zip(table_data, assoc_items) do
              attrs = prepare_attrs(model, row)
              insert(repo_name, factory_name, [{assoc_field, assoc_item} | attrs])
            end
        end

      {:ok, %{state | existing: Map.put(existing, model, items)}}
    end
  )

  given_(
    ~r/an? (?<entity_name>[\w\s]+) with the following fields exist:/,
    fn %{existing: existing} = state, %{entity_name: entity_name, table_data: table_data} ->
      entity_name = Inflex.singularize(entity_name)
      model = entity_name_to_model(entity_name)

      table_data = transpose_table(table_data)
      attrs = prepare_attrs(model, table_data)

      item =
        case entity_name_to_factory_args(entity_name) do
          {nil, factory_name} -> build(factory_name, attrs)
          {repo_name, factory_name} -> insert(repo_name, factory_name, attrs)
        end

      {:ok, %{state | existing: Map.put(existing, model, [item])}}
    end
  )

  given_(
    ~r/^I have a signed content with the following fields:$/,
    fn state, %{table_data: table_data} ->
      content =
        table_data
        |> transpose_table()
        |> prepare_input_attrs()

      encoded_content =
        content
        |> Jason.encode!()
        |> Base.encode64()

      state =
        Map.merge(state, %{
          content: content,
          signed_content: %{content: encoded_content, encoding: "BASE64"}
        })

      {:ok, state}
    end
  )

  given_(
    ~r/^I have a signed content with field "(?<field>[^"]+)" and the following nested fields:$/,
    fn state, %{field: field, table_data: table_data} ->
      content =
        table_data
        |> transpose_table()
        |> prepare_input_attrs()

      content = Map.put(%{}, field, content)

      encoded_content =
        content
        |> Jason.encode!()
        |> Base.encode64()

      state =
        Map.merge(state, %{
          content: content,
          signed_content: %{content: encoded_content, encoding: "BASE64"}
        })

      {:ok, state}
    end
  )

  given_(
    ~r/^the following signatures was applied:$/,
    fn %{content: content} = state, %{table_data: table_data} ->
      signers = Enum.map(table_data, &prepare_input_attrs/1)

      stub(SignatureMock, :decode_and_validate, fn _, _ ->
        {:ok,
         %{
           "content" => content,
           "signatures" =>
             Enum.map(signers, fn signer ->
               %{
                 "is_valid" => Map.get(signer, :is_valid, true),
                 "is_stamp" => Map.get(signer, :is_stamp, false),
                 "signer" => %{"edrpou" => signer[:edrpou], "drfo" => signer[:drfo], "surname" => signer[:surname]}
               }
             end)
         }}
      end)

      {:ok, state}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests$/,
    fn %{conn: conn} = state, %{count: count} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contract requests$/,
    fn %{conn: conn} = state, %{count: count} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contracts$/,
    fn %{conn: conn} = state, %{count: count} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contracts$/,
    fn %{conn: conn} = state, %{count: count} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medical programs$/,
    fn %{conn: conn} = state, %{count: count} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNMs$/,
    fn %{conn: conn} = state, %{count: count} ->
      query = """
        query ListINNMs($first: Int!) {
          innms(first: $first) {
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

      resp_entities = get_in(resp_body, ~w(data innms nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) service groups$/,
    fn %{conn: conn} = state, %{count: count} ->
      query = """
        query ListServiceGroups($first: Int!) {
          serviceGroups(first: $first) {
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

      resp_entities = get_in(resp_body, ~w(data serviceGroups nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees$/,
    fn %{conn: conn} = state, %{count: count} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) settlements$/,
    fn %{existing: existing, conn: conn} = state, %{count: count} ->
      expect(RPCWorkerMock, :run, fn
        _, Uaddresses.Rpc, :search_settlements, _ -> {:ok, existing[Settlement]}
      end)

      query = """
        query ListSettlements($first: Int!) {
          settlements(first: $first) {
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

      resp_entities = get_in(resp_body, ~w(data settlements nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the first (?<count>\d+) settlements$/,
    fn %{existing: existing, conn: conn} = state, %{nested_field: nested_field, field: field, count: count} ->
      expect(RPCWorkerMock, :run, fn
        _, Uaddresses.Rpc, :search_settlements, _ -> {:ok, existing[Settlement]}
      end)

      expect(RPCWorkerMock, :run, length(existing[Settlement]), fn
        _, Uaddresses.Rpc, :search_regions, _ ->
          {:ok, existing[Region]}

        _, Uaddresses.Rpc, :search_districts, _ ->
          {:ok, existing[District]}

        _, Uaddresses.Rpc, :search_settlements, _ ->
          {:ok, existing[Settlement]}
      end)

      query = """
        query ListSettlements($first: Int!) {
          settlements(first: $first) {
            nodes {
              #{field} {
                #{nested_field}
              }
            }
          }
        }
      """

      variables = %{first: Jason.decode!(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data settlements nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contracts where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListCapitationContractsWithFilter(
          $first: Int!
          $filter: CapitationContractFilter!
        ) {
          capitationContracts(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contracts where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListReimbursementContractsWithFilter(
          $first: Int!
          $filter: ReimbursementContractFilter!
        ) {
          reimbursementContracts(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) legal entities where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListLegalEntitiesWithFilter(
          $first: Int!
          $filter: LegalEntityFilter!
        ) {
          legalEntities(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data legalEntities nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medical programs where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medications where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListMedicationsWithFilter(
          $first: Int!
          $filter: MedicationFilter!
        ) {
          medications(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data medications nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNMs where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListINNMsWithFilter(
          $first: Int!
          $filter: INNMFilter!
        ) {
          innms(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data innms nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNM dosages where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListINNMDosages($first: Int!, $filter: INNMDosageFilter!) {
          innmDosages(first: $first, filter: $filter) {
            nodes {
              databaseId
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

      resp_entities = get_in(resp_body, ~w(data innmDosages nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNM dosages where INNM (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListINNMDosages($first: Int!, $filter: INNMDosageFilter!) {
          innmDosages(first: $first, filter: $filter) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        filter: filter_argument("ingredients", "innm", field, Jason.decode!(value))
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data innmDosages nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) service groups where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListServiceGroupsWithFilter(
          $first: Int!
          $filter: ServiceGroupFilter!
        ) {
          serviceGroups(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data serviceGroups nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) settlements where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{existing: existing, conn: conn} = state, %{count: count, field: field, value: value} ->
      expect(RPCWorkerMock, :run, fn
        _, Uaddresses.Rpc, :search_settlements, _ -> {:ok, tl(existing[Settlement])}
      end)

      query = """
        query ListSettlementsWithFilter(
          $first: Int!
          $filter: SettlementFilter!
        ) {
          settlements(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data settlements nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, association_field: association_field, field: field, value: value} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, association_field: association_field, field: field, value: value} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contracts where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, association_field: association_field, field: field, value: value} ->
      query = """
        query ListCapitationContractsWithAssocFilter(
          $first: Int!
          $filter: CapitationContractFilter!
        ) {
          capitationContracts(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contracts where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, association_field: association_field, field: field, value: value} ->
      query = """
        query ListReimbursementContractsWithAssocFilter(
          $first: Int!
          $filter: ReimbursementContractFilter!
        ) {
          reimbursementContracts(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medications where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, association_field: association_field, field: field, value: value} ->
      query = """
        query ListMedicationsWithAssocFilter(
          $first: Int!
          $filter: MedicationFilter!
        ) {
          medications(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data medications nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, association_field: association_field, field: field, value: value} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) service groups where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, association_field: association_field, field: field, value: value} ->
      query = """
        query ListServiceGroupsWithAssocFilter(
          $first: Int!
          $filter: ServiceGroupFilter!
        ) {
          serviceGroups(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data serviceGroups nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employee requests$/,
    fn %{conn: conn} = state, %{count: count} ->
      query = """
        query ListEmployeeRequests($first: Int!) {
          employeeRequests(first: $first) {
            nodes {
              databaseId
              status
            }
          }
        }
      """

      variables = %{first: Jason.decode!(count)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employeeRequests nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employee requests where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, field: field, value: value} ->
      query = """
        query ListEmployeeRequestsWithFilter($first: Int!, $filter: EmployeeRequestFilter) {
          employeeRequests(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data employeeRequests nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) (?<entity>(\w+\s?){1,3}) where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, params ->
      {:ok, Map.merge(state, call_list_with_filter_query(conn, params))}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) of the (?<nested_association_field>\w+) nested in associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state,
       %{
         count: count,
         association_field: association_field,
         nested_association_field: nested_association_field,
         field: field,
         value: value
       } ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) of the (?<nested_association_field>\w+) nested in associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state,
       %{
         count: count,
         association_field: association_field,
         nested_association_field: nested_association_field,
         field: field,
         value: value
       } ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) legal entities where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn} = state, %{count: count, association_field: association_field, field: field, value: value} ->
      query = """
        query ListLegalEntitiesQuery($first: Int!, $filter: LegalEntityFilter!) {
          legalEntities(first: $first, filter: $filter) {
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

      resp_entities = get_in(resp_body, ~w(data legalEntities nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contract requests sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contracts sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
      query = """
        query ListCapitationContractsWithOrderBy(
          $first: Int!
          $order_by: CapitationContractOrderBy!
        ) {
          capitationContracts(first: $first, order_by: $order_by) {
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

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contracts sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
      query = """
        query ListReimbursementContractsWithOrderBy(
          $first: Int!
          $order_by: ReimbursementContractOrderBy!
        ) {
          reimbursementContracts(first: $first, order_by: $order_by) {
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

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medical programs sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medications sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
      query = """
        query ListMedicationsWithOrderBy(
          $first: Int!
          $order_by: MedicationOrderBy!
        ) {
          medications(first: $first, order_by: $order_by) {
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

      resp_entities = get_in(resp_body, ~w(data medications nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNMs sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
      query = """
        query ListINNMsWithOrderBy(
          $first: Int!
          $order_by: INNMOrderBy!
        ) {
          innms(first: $first, order_by: $order_by) {
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

      resp_entities = get_in(resp_body, ~w(data innms nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNM dosages$/,
    fn %{conn: conn} = state, %{count: count} ->
      query = """
        query ListINNMDosages($first: Int!) {
          innmDosages(first: $first) {
            nodes {
              id
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data innmDosages nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNM dosages sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
      query = """
        query ListINNMDosagesWithOrderBy(
          $first: Int!
          $order_by: INNMDosageOrderBy!
        ) {
          innmDosages(first: $first, order_by: $order_by) {
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

      resp_entities = get_in(resp_body, ~w(data innmDosages nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) service groups sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
      query = """
        query ListServiceGroupsWithOrderBy(
          $first: Int!
          $order_by: ServiceGroupOrderBy!
        ) {
          serviceGroups(first: $first, order_by: $order_by) {
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

      resp_entities = get_in(resp_body, ~w(data serviceGroups nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employee requests sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, %{count: count, field: field, direction: direction} ->
      query_field =
        case field do
          "fullName" -> "lastName"
          field -> field
        end

      query = """
        query ListEmployeeRequestsWithOrderBy(
          $first: Int!
          $order_by: EmployeeRequestOrderBy!
        ) {
          employeeRequests(first: $first, order_by: $order_by) {
            nodes {
              #{query_field}
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

      resp_entities = get_in(resp_body, ~w(data employeeRequests nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees sorted by (?<field>\w+) of the associated (?<association_field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state,
       %{count: count, field: field, association_field: association_field, direction: direction} ->
      query = """
        query ListEmployeesWithOrderBy(
          $first: Int!
          $order_by: EmployeeOrderBy!
        ) {
          employees(first: $first, order_by: $order_by) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{
        first: Jason.decode!(count),
        order_by: order_by_argument(association_field, field, direction)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) settlements sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{existing: existing, conn: conn} = state, %{count: count, field: field, direction: direction} ->
      expect(RPCWorkerMock, :run, fn
        _, Uaddresses.Rpc, :search_settlements, _ -> {:ok, Enum.reverse(existing[Settlement])}
      end)

      query = """
        query ListSettlementsWithOrderBy(
          $first: Int!
          $order_by: SettlementOrderBy!
        ) {
          settlements(first: $first, order_by: $order_by) {
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

      resp_entities = get_in(resp_body, ~w(data settlements nodes))

      {:ok, %{state | resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) (?<entity>(\w+\s?){1,3}) sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn} = state, params ->
      {:ok, Map.merge(state, call_list_with_order_by_query(conn, params))}
    end
  )

  when_(
    ~r/^I request capitation contract request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request reimbursement contract request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request employee where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request employee request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
      query = """
        query GetEmployeeRequestQuery($id: ID!) {
          employeeRequest(id: $id) {
            databaseId
          }
        }
      """

      variables = %{id: Node.to_global_id("EmployeeRequest", database_id)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employeeRequest))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request INNM where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
      query = """
        query GetINNMQuery($id: ID!) {
          innm(id: $id) {
            databaseId
          }
        }
      """

      variables = %{
        id: Node.to_global_id("INNM", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data innm))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the INNM dosage where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
      query = """
        query GetINNMDosageQuery($id: ID!) {
          innmDosage(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("INNMDosage", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data innmDosage))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request INNM dosage with INNM where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
      query = """
        query GetINNMDosageQuery($id: ID!) {
          innmDosage(id: $id) {
            ingredients {
              innm {
                id
                databaseId
              }
            }
          }
        }
      """

      variables = %{
        id: Node.to_global_id("INNMDosage", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data innmDosage))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the capitation contract where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
      query = """
        query GetCapitationContractQuery($id: ID!) {
          capitationContract(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("CapitationContract", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data capitationContract))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the reimbursement contract where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
      query = """
        query GetReimbursementContractQuery($id: ID!) {
          reimbursementContract(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("ReimbursementContract", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContract))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the reimbursement contract request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the medical program where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
      query = """
        query GetMedicationQuery($id: ID!) {
          medication(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("Medication", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data medication))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the INNM where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
      query = """
        query GetINNMQuery($id: ID!) {
          innm(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("INNM", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data innm))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the service group where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
      query = """
        query GetServiceGroupQuery($id: ID!) {
          serviceGroup(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("ServiceGroup", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data serviceGroup))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the employee where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the employee request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
      query = """
        query GetEmployeeRequestQuery($id: ID!) {
          employeeRequest(id: $id) {
            #{field}
          }
        }
      """

      variables = %{id: Node.to_global_id("EmployeeRequest", database_id)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employeeRequest))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the legal entity where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{field: field, database_id: database_id} ->
      query = """
        query GetLegalEntityQuery($id: ID!) {
          legalEntity(id: $id) {
            #{field}
          }
        }
      """

      variables = %{
        id: Node.to_global_id("LegalEntity", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data legalEntity))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the (?<entity>(\w+\s?){1,3}) where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, params ->
      {:ok, Map.merge(state, call_details_query(conn, params))}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the reimbursement contract request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{nested_field: nested_field, field: field, database_id: database_id} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{nested_field: nested_field, field: field, database_id: database_id} ->
      query = """
        query GetMedicationQuery($id: ID!) {
          medication(id: $id) {
            #{field} {
              #{nested_field}
            }
          }
        }
      """

      variables = %{
        id: Node.to_global_id("Medication", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data medication))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the legal entity where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{nested_field: nested_field, field: field, database_id: database_id} ->
      query = """
        query GetLegalEntityQuery($id: ID!) {
          legalEntity(id: $id) {
            #{field} {
              #{nested_field}
            }
          }
        }
      """

      variables = %{
        id: Node.to_global_id("LegalEntity", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data legalEntity))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the employee where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{nested_field: nested_field, field: field, database_id: database_id} ->
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

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the employee request where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{nested_field: nested_field, field: field, database_id: database_id} ->
      query = """
        query GetEmployeeRequestQuery($id: ID!) {
          employeeRequest(id: $id) {
            #{field} {
              #{nested_field}
            }
          }
        }
      """

      variables = %{id: Node.to_global_id("EmployeeRequest", database_id)}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employeeRequest))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the service group where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{nested_field: nested_field, field: field, database_id: database_id} ->
      query = """
        query GetServiceGroupQuery($id: ID!) {
          serviceGroup(id: $id) {
            #{field} {
              #{nested_field}
            }
          }
        }
      """

      variables = %{
        id: Node.to_global_id("ServiceGroup", database_id)
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data serviceGroup))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I create (?<entity>(\w+\s?)+) with attributes:$/,
    fn %{conn: conn} = state, %{entity: entity, table_data: [row]} ->
      {:ok, Map.merge(state, call_create_entity_mutation(conn, entity, row))}
    end
  )

  when_(
    ~r/^I merge legal entities with signed content$/,
    fn %{conn: conn, content: content, signed_content: signed_content} = state, _ ->
      job = build(:legal_entity_merge_job, meta: Map.take(content, ~w(merged_to_legal_entity merged_from_legal_entity)))

      stub(RPCWorkerMock, :run, fn _, _, :create_job, [tasks, _type, _opts] ->
        assert 1 == length(tasks)
        %{name: name, callback: {_, m, f, a}} = hd(tasks)
        assert LegalEntityMergeJob = m
        assert :merge = f
        assert is_map(hd(a))
        assert "Merge legal entity" == name

        {:ok, job}
      end)

      query = """
        mutation MergeLegalEntitiesMutation($input: MergeLegalEntitiesInput!) {
          mergeLegalEntities(input: $input) {
            legalEntityMergeJob {
              id
              status
            }
          }
        }
      """

      variables = %{
        input: %{signedContent: signed_content}
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data mergeLegalEntities legalEntityMergeJob))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I create employee request with signed content$/,
    fn %{conn: conn, signed_content: signed_content} = state, _ ->
      template()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _ ->
        {:ok, "success"}
      end)

      query = """
        mutation CreateEmployeeRequest($input: CreateEmployeeRequestInput!) {
          createEmployeeRequest(input: $input) {
            employeeRequest {
              databaseId
              status
            }
          }
        }
      """

      variables = %{
        input: %{signedContent: signed_content}
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data createEmployeeRequest employeeRequest))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I create contract request with signed content and attributes:$/,
    fn %{conn: conn, signed_content: signed_content} = state, %{table_data: [row]} ->
      stub(MediaStorageMock, :store_signed_content, fn _, _, _, _ ->
        {:ok, "success"}
      end)

      stub(MediaStorageMock, :create_signed_url, fn _, _, resource, _ ->
        {:ok, %{secret_url: "http://some_url/#{resource}"}}
      end)

      stub(MediaStorageMock, :get_signed_content, fn _url -> {:ok, %{status_code: 200, body: ""}} end)
      stub(MediaStorageMock, :save_file, fn _, _, _, _ -> {:ok, nil} end)

      query = """
        mutation CreateContractRequest($input: CreateContractRequestInput!) {
          createContractRequest(input: $input) {
            contractRequest {
              databaseId
              status
              assignee {
                databaseId
              }
            }
          }
        }
      """

      input =
        row
        |> prepare_input_attrs()
        |> Map.put(:signedContent, signed_content)

      variables = %{input: input}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data createContractRequest contractRequest))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I update the status to "(?<status>[^"]+)" with reason "(?<reason>[^"]+)" in legal entity where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{status: status, reason: reason, database_id: database_id} ->
      query = """
        mutation UpdateLegalEntityStatusMutation($input: UpdateLegalEntityStatusInput) {
          updateLegalEntityStatus(input: $input) {
            legalEntity {
              status
              statusReason
            }
          }
        }
      """

      variables = %{
        input: %{
          id: Node.to_global_id("LegalEntity", database_id),
          status: status,
          reason: reason
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data updateLegalEntityStatus legalEntity))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I update the (?<field>\w+) with (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*})) in the program medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id, field: field, value: value} ->
      query = """
        mutation UpdateProgramMedicationMutation($input: UpdateProgramMedicationInput!) {
          updateProgramMedication(input: $input) {
            programMedication {
              #{field}
            }
          }
        }
      """

      variables = %{
        input: %{
          :id => Node.to_global_id("ProgramMedication", database_id),
          field => Jason.decode!(value)
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data updateProgramMedication programMedication))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I update the (?<nested_field>\w+) of the (?<field>\w+) with (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*})) in the program medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id, field: field, nested_field: nested_field, value: value} ->
      query = """
        mutation UpdateProgramMedicationMutation($input: UpdateProgramMedicationInput!) {
          updateProgramMedication(input: $input) {
            programMedication {
              #{field} {
                #{nested_field}
              }
            }
          }
        }
      """

      variables = %{
        input: %{
          :id => Node.to_global_id("ProgramMedication", database_id),
          field => %{
            nested_field => Jason.decode!(value)
          }
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data updateProgramMedication programMedication))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I deactivate employee where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
      query = """
      mutation DeactivateEmployee($input: DeactivateEmployeeInput!) {
        deactivateEmployee(input: $input) {
          employee {
            databaseId
            status
          }
        }
      }
      """

      variables = %{
        input: %{
          id: Node.to_global_id("Employee", database_id)
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data deactivateEmployee employee))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I deactivate medical program where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
      query = """
      mutation DeactivateMedicalProgram($input: DeactivateMedicalProgramInput!) {
        deactivateMedicalProgram(input: $input) {
          medicalProgram {
            databaseId
            isActive
          }
        }
      }
      """

      variables = %{
        input: %{
          id: Node.to_global_id("MedicalProgram", database_id)
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data deactivateMedicalProgram medicalProgram))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I deactivate service where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
      query = """
      mutation DeactivateService($input: DeactivateServiceInput!) {
        deactivateService(input: $input) {
          service {
            databaseId
            isActive
          }
        }
      }
      """

      variables = %{
        input: %{
          id: Node.to_global_id("Service", database_id)
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data deactivateService service))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I deactivate medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
      query = """
      mutation DeactivateMedication($input: DeactivateMedicationInput!) {
        deactivateMedication(input: $input) {
          medication {
            databaseId
            isActive
          }
        }
      }
      """

      variables = %{
        input: %{
          id: Node.to_global_id("Medication", database_id)
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data deactivateMedication medication))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I deactivate INNM dosage where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id} ->
      query = """
      mutation DeactivateINNMDosage($input: DeactivateINNMDosageInput!) {
        deactivateInnmDosage(input: $input) {
          innmDosage {
            databaseId
            isActive
          }
        }
      }
      """

      variables = %{
        input: %{
          id: Node.to_global_id("INNMDosage", database_id)
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data deactivateInnmDosage innmDosage))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I suspend (?<contract_type>\w+) contract where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id, contract_type: contract_type} ->
      query = """
      mutation SuspendContract($input: SuspendContractInput!) {
        suspendContract(input: $input) {
          contract {
            id
            databaseId
            isSuspended
            statusReason
            reason
          }
        }
      }
      """

      contract_type =
        case contract_type do
          "capitation" -> "CapitationContract"
          "reimbursement" -> "ReimbursementContract"
        end

      variables = %{
        input: %{
          id: Node.to_global_id(contract_type, database_id),
          is_suspended: true,
          status_reason: "DEFAULT",
          reason: "Custom reason"
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data suspendContract contract))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I verify by NHS with (?<nhs_verified>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*})) legal entity where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn} = state, %{database_id: database_id, nhs_verified: nhs_verified} ->
      query = """
        mutation NHSVerifyLegalEntityMutation($input: NhsVerifyLegalEntityInput) {
          nhsVerifyLegalEntity(input: $input) {
            legalEntity {
              nhsVerified
              nhsUnverifiedAt
            }
          }
        }
      """

      variables = %{
        input: %{
          id: Node.to_global_id("LegalEntity", database_id),
          nhsVerified: Jason.decode!(nhs_verified)
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data nhsVerifyLegalEntity legalEntity))

      {:ok, %{state | resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  then_(
    ~r/^event would be published to event manager$/,
    fn state, _ ->
      expect(KafkaMock, :publish_to_event_manager, fn _event -> :ok end)

      {:ok, state}
    end
  )

  then_("no errors should be returned", fn %{resp_body: resp_body} = state ->
    refute resp_body["errors"]

    {:ok, state}
  end)

  then_(
    ~r/^the "(?<code>[^"]+)" error should be returned$/,
    fn %{resp_body: resp_body} = state, %{code: code} ->
      assert Map.has_key?(resp_body, "errors"), "Response body does not have `errors` field"

      assert Enum.any?(
               resp_body["errors"],
               fn error -> %{"extensions" => %{"code" => ^code}} = error end
             )

      {:ok, state}
    end
  )

  then_("request id should be returned", fn %{resp_body: resp_body} = state ->
    assert %{"extensions" => %{"requestId" => _}} = resp_body

    {:ok, state}
  end)

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
    ~r/^the (?<field>\w+) of the first item in the collection should be (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{resp_entities: resp_entities} = state, %{field: field, value: value} ->
      expected_value = Jason.decode!(value)
      resp_value = hd(resp_entities)[field]

      assert expected_value == resp_value

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<field>\w+) in the (?<association_field>\w+) of the first item in the collection should be (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{resp_entities: resp_entities} = state, %{field: field, association_field: association_field, value: value} ->
      expected_value = Jason.decode!(value)
      resp_value = resp_entities |> hd() |> get_in([association_field, field])

      assert expected_value == resp_value

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<field>\w+) of the requested item should be (?<negate>not )?(?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{resp_entity: resp_entity} = state, %{field: field, value: value, negate: negate} ->
      expected_value = Jason.decode!(value)
      resp_value = resp_entity[field]

      case String.length(negate) do
        0 -> assert expected_value == resp_value
        _ -> assert expected_value != resp_value
      end

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<nested_field>\w+) in the (?<field>\w+) of the requested item should be (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{resp_entity: resp_entity} = state, %{field: field, nested_field: nested_field, value: value} ->
      expected_value = Jason.decode!(value)
      resp_value = get_in(resp_entity, [field, nested_field])

      assert expected_value == resp_value

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<field>\w+) of the requested item should have the following fields:$/,
    fn %{resp_entity: resp_entity} = state, %{field: field, table_data: table_data} ->
      expected_value = for {key, value} <- transpose_table(table_data), do: {key, Jason.decode!(value)}, into: %{}
      resp_value = resp_entity[field]

      assert expected_value == resp_value

      {:ok, state}
    end
  )

  then_(
    ~r/^the (?<expected_field>\w+) of the (?<entity_name>(\w+\s?)+) where (?<lookup_field>\w+) is (?<lookup_value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*})) should be (?<expected_value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn state,
       %{
         entity_name: entity_name,
         lookup_field: lookup_field,
         lookup_value: lookup_value,
         expected_field: expected_field,
         expected_value: expected_value
       } ->
      entity_name = Inflex.singularize(entity_name)
      model = entity_name_to_model(entity_name)
      repo = model_to_repo(model)

      lookup_field = prepare_field(lookup_field)
      lookup_value = prepare_value!(model, lookup_field, lookup_value)

      expected_field = prepare_field(expected_field)
      expected_value = prepare_value!(model, expected_field, expected_value)

      actual_value =
        model
        |> where([r], field(r, ^lookup_field) == ^lookup_value)
        |> select([r], field(r, ^expected_field))
        |> repo.one()

      assert expected_value == actual_value

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

  @spec entity_name_to_model(entity_name :: binary) :: module
  def entity_name_to_model(entity_name)

  def entity_name_to_model("dictionary"), do: Dictionary
  def entity_name_to_model("legal entity"), do: LegalEntity
  def entity_name_to_model("related legal entity"), do: RelatedLegalEntity
  def entity_name_to_model("division"), do: Division
  def entity_name_to_model("employee"), do: Employee
  def entity_name_to_model("employee request"), do: EmployeeRequest
  def entity_name_to_model("party"), do: Party
  def entity_name_to_model("party user"), do: PartyUser
  def entity_name_to_model("capitation contract request"), do: CapitationContractRequest
  def entity_name_to_model("reimbursement contract request"), do: ReimbursementContractRequest
  def entity_name_to_model("capitation contract"), do: CapitationContract
  def entity_name_to_model("reimbursement contract"), do: ReimbursementContract
  def entity_name_to_model("contract division"), do: ContractDivision
  def entity_name_to_model("contract employee"), do: ContractEmployee
  def entity_name_to_model("medical program"), do: MedicalProgram
  def entity_name_to_model("program medication"), do: ProgramMedication
  def entity_name_to_model("medication"), do: Medication
  def entity_name_to_model("medication ingredient"), do: Medication.Ingredient
  def entity_name_to_model("INNM dosage"), do: INNMDosage
  def entity_name_to_model("INNM dosage ingredient"), do: INNMDosage.Ingredient
  def entity_name_to_model("INNM"), do: INNM
  def entity_name_to_model("service group"), do: ServiceGroup
  def entity_name_to_model("region"), do: Region
  def entity_name_to_model("district"), do: District
  def entity_name_to_model("settlement"), do: Settlement
  def entity_name_to_model("service"), do: Service
  def entity_name_to_model("service group"), do: ServiceGroup
  def entity_name_to_model("services group"), do: ServicesGroups
  def entity_name_to_model("program service"), do: ProgramService
  def entity_name_to_model(entity_name), do: raise("Model not found for #{inspect(entity_name)}")

  @spec entity_name_to_model(entity_name :: binary) :: {repo :: atom, factory_name :: atom}
  def entity_name_to_factory_args(entity_name)

  def entity_name_to_factory_args("dictionary"), do: {:il, :dictionary}
  def entity_name_to_factory_args("legal entity"), do: {:prm, :legal_entity}
  def entity_name_to_factory_args("related legal entity"), do: {:prm, :related_legal_entity}
  def entity_name_to_factory_args("division"), do: {:prm, :division}
  def entity_name_to_factory_args("employee"), do: {:prm, :employee}
  def entity_name_to_factory_args("employee request"), do: {:il, :employee_request}
  def entity_name_to_factory_args("party"), do: {:prm, :party}
  def entity_name_to_factory_args("party user"), do: {:prm, :party_user}
  def entity_name_to_factory_args("capitation contract request"), do: {:il, :capitation_contract_request}
  def entity_name_to_factory_args("reimbursement contract request"), do: {:il, :reimbursement_contract_request}
  def entity_name_to_factory_args("capitation contract"), do: {:prm, :capitation_contract}
  def entity_name_to_factory_args("reimbursement contract"), do: {:prm, :reimbursement_contract}
  def entity_name_to_factory_args("contract division"), do: {:prm, :contract_division}
  def entity_name_to_factory_args("contract employee"), do: {:prm, :contract_employee}
  def entity_name_to_factory_args("program service"), do: {:prm, :program_service}
  def entity_name_to_factory_args("service"), do: {:prm, :service}
  def entity_name_to_factory_args("service group"), do: {:prm, :service_group}
  def entity_name_to_factory_args("services group"), do: {:prm, :services_groups}
  def entity_name_to_factory_args("medical program"), do: {:prm, :medical_program}
  def entity_name_to_factory_args("program medication"), do: {:prm, :program_medication}
  def entity_name_to_factory_args("medication"), do: {:prm, :medication}
  def entity_name_to_factory_args("medication ingredient"), do: {:prm, :ingredient_medication}
  def entity_name_to_factory_args("INNM dosage"), do: {:prm, :innm_dosage}
  def entity_name_to_factory_args("INNM dosage ingredient"), do: {:prm, :ingredient_innm_dosage}
  def entity_name_to_factory_args("INNM"), do: {:prm, :innm}
  def entity_name_to_factory_args("service group"), do: {:prm, :service_group}
  def entity_name_to_factory_args("region"), do: {nil, :region}
  def entity_name_to_factory_args("district"), do: {nil, :district}
  def entity_name_to_factory_args("settlement"), do: {nil, :settlement}
  def entity_name_to_factory_args(entity_name), do: raise("Factory not found for #{inspect(entity_name)}")

  @spec model_to_repo(model :: module) :: module
  def model_to_repo(model)

  def model_to_repo(Dictionary), do: Repo
  def model_to_repo(LegalEntity), do: PRMRepo
  def model_to_repo(RelatedLegalEntity), do: PRMRepo
  def model_to_repo(Division), do: PRMRepo
  def model_to_repo(Employee), do: PRMRepo
  def model_to_repo(EmployeeRequest), do: Repo
  def model_to_repo(Party), do: PRMRepo
  def model_to_repo(PartyUser), do: PRMRepo
  def model_to_repo(CapitationContractRequest), do: Repo
  def model_to_repo(ReimbursementContractRequest), do: Repo
  def model_to_repo(CapitationContract), do: PRMRepo
  def model_to_repo(ReimbursementContract), do: PRMRepo
  def model_to_repo(ContractDivision), do: PRMRepo
  def model_to_repo(ContractEmployee), do: PRMRepo
  def model_to_repo(MedicalProgram), do: PRMRepo
  def model_to_repo(ProgramMedication), do: PRMRepo
  def model_to_repo(ProgramService), do: PRMRepo
  def model_to_repo(Service), do: PRMRepo
  def model_to_repo(ServiceGroup), do: PRMRepo
  def model_to_repo(ServicesGroups), do: PRMRepo
  def model_to_repo(Medication), do: PRMRepo
  def model_to_repo(Medication.Ingredient), do: PRMRepo
  def model_to_repo(INNMDosage), do: PRMRepo
  def model_to_repo(INNMDosage.Ingredient), do: PRMRepo
  def model_to_repo(INNM), do: PRMRepo
  def model_to_repo(ServiceGroup), do: PRMRepo
  def model_to_repo(model), do: raise("Repo not found for #{inspect(model)}")

  def transpose_table(table_data) do
    Enum.into(table_data, %{}, &{&1.field, &1.value})
  end

  def prepare_input_attrs(attrs), do: attrs |> Enum.map(&prepare_input_field/1) |> Map.new()

  defp prepare_input_field({field, ""}), do: {field, ""}

  defp prepare_input_field({field, value}) do
    case Jason.decode(value) do
      {:ok, decoded_value} -> {field, decoded_value}
      _ -> raise "Unable to parse \"#{value}\" as value for field \"#{field}\"."
    end
  end

  def prepare_attrs(queryable \\ nil, attrs)

  def prepare_attrs(queryable, attrs) when is_map(attrs) do
    prepare_attrs(queryable, Map.to_list(attrs))
  end

  def prepare_attrs(_, []), do: []

  def prepare_attrs(queryable, [{field, value} | tail]) do
    field = prepare_field(field)
    value = prepare_value!(queryable, field, value)

    [{field, value} | prepare_attrs(queryable, tail)]
  end

  defp prepare_field(:databaseId), do: :id
  defp prepare_field("databaseId"), do: :id

  defp prepare_field(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> prepare_field()
  end

  defp prepare_field(key) when is_binary(key) do
    key
    |> Macro.underscore()
    |> String.to_atom()
  end

  defp prepare_value!(queryable, field, value) do
    with {:ok, value} <- prepare_value(queryable, field, value) do
      value
    else
      _ -> raise "Unable to parse \"#{value}\" as value for field \"#{field}\"."
    end
  end

  defp prepare_value(_, _, "null"), do: {:ok, nil}

  defp prepare_value(nil, _, value), do: {:ok, value}

  defp prepare_value(queryable, field, value) do
    case introspect(queryable, field) do
      :date ->
        with {:ok, value} <- Jason.decode(value), do: Date.from_iso8601(value)

      :utc_datetime ->
        with {:ok, value} <- Jason.decode(value),
             {:ok, datetime, _} <- DateTime.from_iso8601(value) do
          {:ok, datetime}
        end

      :utc_datetime_usec ->
        with {:ok, value} <- Jason.decode(value),
             {:ok, datetime, _} <- DateTime.from_iso8601(value) do
          {:ok, datetime}
        end

      :naive_datetime ->
        with {:ok, value} <- Jason.decode(value), do: NaiveDateTime.from_iso8601(value)

      %Ecto.Embedded{} ->
        Jason.decode(value, keys: :atoms)

      _ ->
        Jason.decode(value)
    end
  end

  defp introspect(queryable, field) do
    do_introspect = &queryable.__schema__(&1, field)
    do_introspect.(:association) || do_introspect.(:embed) || do_introspect.(:type)
  end

  def filter_argument(field, value), do: %{field => value}
  def filter_argument(assoc, field, value), do: %{assoc => %{field => value}}
  def filter_argument(assoc, nested_assoc, field, value), do: %{assoc => %{nested_assoc => %{field => value}}}

  def order_by_argument(assoc, field, direction), do: order_by_argument(assoc <> Inflex.camelize(field), direction)

  def order_by_argument(field, "ascending"), do: order_by_argument(field, "ASC")
  def order_by_argument(field, "descending"), do: order_by_argument(field, "DESC")

  def order_by_argument(field, direction) do
    field =
      field
      |> Macro.underscore()
      |> String.upcase()

    Enum.join([field, direction], "_")
  end

  defp call_details_query(conn, %{entity: entity, field: field, database_id: database_id}) do
    capitalized = entity |> String.capitalize() |> camelcase()
    downcased = entity |> String.downcase() |> camelcase()

    query = """
      query Get#{capitalized}Query($id: ID!) {
        #{downcased}(id: $id) {
          #{field}
        }
      }
    """

    variables = %{
      id: Node.to_global_id(capitalized, database_id)
    }

    resp_body =
      conn
      |> post_query(query, variables)
      |> json_response(200)

    resp_entity = get_in(resp_body, ["data", downcased])

    %{resp_body: resp_body, resp_entity: resp_entity}
  end

  defp call_list_with_filter_query(conn, %{entity: entity, count: count, field: field, value: value}) do
    capitalized = entity |> String.capitalize() |> camelcase()
    downcased = entity |> String.downcase() |> camelcase()

    query = """
      query List#{capitalized}WithFilter(
        $first: Int!
        $filter: #{Inflex.singularize(capitalized)}Filter!
      ) {
        #{downcased}(first: $first, filter: $filter) {
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

    resp_entities = get_in(resp_body, ["data", downcased, "nodes"])

    %{resp_body: resp_body, resp_entities: resp_entities}
  end

  defp call_list_with_order_by_query(conn, %{entity: entity, count: count, field: field, direction: direction}) do
    capitalized = entity |> String.capitalize() |> camelcase()
    downcased = entity |> String.downcase() |> camelcase()

    query = """
      query List#{capitalized}WithOrderBy(
        $first: Int!
        $order_by: #{Inflex.singularize(capitalized)}OrderBy!
      ) {
        #{downcased}(first: $first, order_by: $order_by) {
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

    resp_entities = get_in(resp_body, ["data", downcased, "nodes"])

    %{resp_body: resp_body, resp_entities: resp_entities}
  end

  defp call_create_entity_mutation(conn, "INNM", input_attrs) do
    input_attrs = prepare_input_attrs(input_attrs)
    return_fields = input_attrs |> Map.keys() |> Enum.join(",")

    query = """
      mutation CreateINNM($input: CreateINNMInput!) {
        createInnm(input: $input) {
          INNM {
            #{return_fields}
          }
        }
      }
    """

    resp_body =
      conn
      |> post_query(query, %{input: input_attrs})
      |> json_response(200)

    resp_entity = get_in(resp_body, ~w(data createInnm INNM))

    %{resp_body: resp_body, resp_entity: resp_entity}
  end

  defp call_create_entity_mutation(conn, "INNM dosage", input_attrs) do
    input_attrs = prepare_input_attrs(input_attrs)
    return_fields = prepare_return_fields(input_attrs)

    query = """
      mutation CreateINNMDosage($input: CreateINNMDosageInput!) {
        createInnmDosage(input: $input) {
          INNMDosage {
            #{return_fields}
          }
        }
      }
    """

    resp_body =
      conn
      |> post_query(query, %{input: input_attrs})
      |> json_response(200)

    resp_entity = get_in(resp_body, ~w(data createInnmDosage INNMDosage))

    %{resp_body: resp_body, resp_entity: resp_entity}
  end

  defp call_create_entity_mutation(conn, entity, input_attrs) do
    input_attrs = prepare_input_attrs(input_attrs)
    return_fields = prepare_return_fields(input_attrs)
    capitalized = entity |> String.capitalize() |> camelcase()
    downcased = entity |> String.downcase() |> camelcase()

    query = """
    mutation Create#{capitalized}($input: Create#{capitalized}Input!) {
      create#{capitalized}(input: $input) {
        #{downcased} {
          #{return_fields}
        }
      }
    }
    """

    resp_body =
      conn
      |> post_query(query, %{input: input_attrs})
      |> json_response(200)

    resp_entity = get_in(resp_body, ["data", "create#{capitalized}", downcased])

    %{resp_body: resp_body, resp_entity: resp_entity}
  end

  defp prepare_return_fields(input_attrs),
    do:
      input_attrs
      |> Enum.reduce([], &prepare_return_fields/2)
      |> Enum.join(",")

  # ToDo: map nested fields
  defp prepare_return_fields({_field, value}, acc) when is_map(value), do: acc
  # ToDo: map list with map
  defp prepare_return_fields({_field, value}, acc) when is_list(value), do: acc

  defp prepare_return_fields({field, _value}, acc), do: [field | acc]

  defp camelcase(string) do
    Regex.replace(~r/(.+)\ (.+)/, string, fn _, b, c -> "#{b}" <> String.capitalize(c) end)
  end
end
