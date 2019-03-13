defmodule GraphQL.Features.Context do
  use WhiteBread.Context
  use Phoenix.ConnTest

  import Core.Expectations.Mithril, only: [get_client_type_name: 1]
  import Core.Factories, only: [build: 2, build_list: 2, insert: 3, insert_list: 3]
  import Ecto.Query, only: [where: 2]
  import Mox, only: [expect: 3, expect: 4]

  alias Absinthe.Relay.Node
  alias Core.{Repo, PRMRepo, EventManagerRepo}
  alias Core.ContractRequests.{CapitationContractRequest, ReimbursementContractRequest}
  alias Core.Contracts.{CapitationContract, ReimbursementContract}
  alias Core.Dictionaries.Dictionary
  alias Core.Employees.Employee
  alias Core.EventManager.Event
  alias Core.LegalEntities.LegalEntity
  alias Core.Medications.{INNMDosage, Medication}
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Medications.Program, as: ProgramMedication
  alias Core.Parties.Party
  alias Core.Uaddresses.{District, Region, Settlement}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
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
    :ok = Sandbox.checkout(EventManagerRepo)

    Mox.Server.verify_on_exit(self())
    Mox.Server.set_mode(self(), :global)

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

  given_(~r/^my consumer ID is "(?<id>[^"]+)"$/, fn %{conn: conn}, %{id: id} ->
    {:ok, %{conn: put_consumer_id(conn, id)}}
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
      count = Jason.decode!(count)
      insert_list(count, :il, :capitation_contract_request)

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
    ~r/^there are (?<count>\d+) capitation contracts exist$/,
    fn state, %{count: count} ->
      count = String.to_integer(count)
      insert_list(count, :prm, :capitation_contract)

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
    ~r/^there are (?<count>\d+) medical programs exist$/,
    fn state, %{count: count} ->
      count = Jason.decode!(count)
      insert_list(count, :prm, :medical_program)

      {:ok, state}
    end
  )

  given_(
    ~r/^there are (?<count>\d+) INNMs exist$/,
    fn state, %{count: count} ->
      count = Jason.decode!(count)
      insert_list(count, :prm, :innm)

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
    ~r/^there are (?<count>\d+) settlements exist$/,
    fn state, %{count: count} ->
      count = Jason.decode!(count)
      settlements = build_list(count, :settlement)
      state = Map.put(state, :settlements, settlements)

      {:ok, state}
    end
  )

  given_(
    ~r/^there are (?<count>\d+) INNM dosages exist$/,
    fn state, %{count: count} ->
      count = Jason.decode!(count)
      insert_list(count, :prm, :innm_dosage)

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
    ~r/^the following capitation contracts exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(CapitationContract, row)

        # FIXME: There are should be better way to set foreign keys
        insert(:prm, :capitation_contract, [
          {:contractor_legal_entity, nil},
          {:contractor_legal_entity_id, UUID.generate()} | attrs
        ])
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following reimbursement contracts exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(ReimbursementContract, row)

        # FIXME: There are should be better way to set foreign keys
        insert(:prm, :reimbursement_contract, [
          {:contractor_legal_entity, nil},
          {:contractor_legal_entity_id, UUID.generate()} | attrs
        ])
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following employees exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(Employee, row)
        # FIXME: There are should be better way to set foreign keys
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
    ~r/^the following dictionaries exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(Dictionary, row)
        insert(:il, :dictionary, attrs)
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
    ~r/^the following medications exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(Medication, row)
        insert(:prm, :medication, attrs)
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following INNMs exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(Medication, row)
        insert(:prm, :innm, attrs)
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following program medications exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(ProgramMedication, row)
        insert(:prm, :program_medication, attrs)
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following medication ingredients exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(Medication.Ingredient, row)
        insert(:prm, :ingredient_medication, attrs)
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following INNM dosage ingredients exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(INNMDosage.Ingredient, row)
        insert(:prm, :ingredient_innm_dosage, attrs)
      end

      {:ok, state}
    end
  )

  given_(
    ~r/^the following INNM dosages exist:$/,
    fn state, %{table_data: table_data} ->
      for row <- table_data do
        attrs = prepare_attrs(INNMDosage, row)
        insert(:prm, :innm_dosage, attrs)
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

  given_(
    ~r/^the following regions exist:$/,
    fn state, %{table_data: table_data} ->
      regions =
        for row <- table_data do
          attrs = prepare_attrs(Region, row)
          build(:region, attrs)
        end

      state = Map.put(state, :regions, regions)

      {:ok, state}
    end
  )

  given_(
    ~r/^the following districts exist:$/,
    fn state, %{table_data: table_data} ->
      districts =
        for row <- table_data do
          attrs = prepare_attrs(District, row)
          build(:district, attrs)
        end

      state = Map.put(state, :districts, districts)

      {:ok, state}
    end
  )

  given_(
    ~r/^the following settlements exist:$/,
    fn state, %{table_data: table_data} ->
      settlements =
        for row <- table_data do
          attrs = prepare_attrs(Settlement, row)
          build(:settlement, attrs)
        end

      state = Map.put(state, :settlements, settlements)

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
    ~r/^I request first (?<count>\d+) INNMs$/,
    fn %{conn: conn}, %{count: count} ->
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
    ~r/^I request first (?<count>\d+) settlements$/,
    fn %{settlements: settlements, conn: conn}, %{count: count} ->
      expect(RPCWorkerMock, :run, fn
        _, Uaddresses.Rpc, :search_settlements, _ -> {:ok, settlements}
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the first (?<count>\d+) settlements$/,
    fn %{conn: conn} = state, %{nested_field: nested_field, field: field, count: count} ->
      expect(RPCWorkerMock, :run, fn
        _, Uaddresses.Rpc, :search_settlements, _ -> {:ok, state[:settlements]}
      end)

      expect(RPCWorkerMock, :run, length(state[:settlements]), fn
        _, Uaddresses.Rpc, :search_regions, _ ->
          {:ok, state[:regions]}

        _, Uaddresses.Rpc, :search_districts, _ ->
          {:ok, state[:districts]}

        _, Uaddresses.Rpc, :search_settlements, _ ->
          {:ok, state[:settlements]}
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
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
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
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
    ~r/^I request first (?<count>\d+) capitation contracts where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contracts where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
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
    ~r/^I request first (?<count>\d+) legal entities where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medical programs where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
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
    ~r/^I request first (?<count>\d+) medications where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNMs where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNM dosages where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) settlements where (?<field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{settlements: settlements, conn: conn}, %{count: count, field: field, value: value} ->
      expect(RPCWorkerMock, :run, fn
        _, Uaddresses.Rpc, :search_settlements, _ -> {:ok, tl(settlements)}
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
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
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
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
    ~r/^I request first (?<count>\d+) capitation contracts where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contracts where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) medications where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) employees where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
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
    ~r/^I request first (?<count>\d+) capitation contract requests where (?<field>\w+) of the (?<nested_association_field>\w+) nested in associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn},
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contract requests where (?<field>\w+) of the (?<nested_association_field>\w+) nested in associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn},
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) legal entities where (?<field>\w+) of the associated (?<association_field>\w+) is (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{conn: conn}, %{count: count, association_field: association_field, field: field, value: value} ->
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
    ~r/^I request first (?<count>\d+) capitation contracts sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) reimbursement contracts sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
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
    ~r/^I request first (?<count>\d+) medications sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNMs sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNM dosages$/,
    fn %{conn: conn}, %{count: count} ->

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

      {:ok, %{resp_body: resp_body, resp_entities: resp_entities}}
    end
  )

  when_(
    ~r/^I request first (?<count>\d+) INNM dosages sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{conn: conn}, %{count: count, field: field, direction: direction} ->
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
    ~r/^I request first (?<count>\d+) settlements sorted by (?<field>\w+) in (?<direction>ascending|descending) order$/,
    fn %{settlements: settlements, conn: conn}, %{count: count, field: field, direction: direction} ->
      expect(RPCWorkerMock, :run, fn
        _, Uaddresses.Rpc, :search_settlements, _ -> {:ok, Enum.reverse(settlements)}
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
    ~r/^I request INNM where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id} ->
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

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the INNM dosage where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{field: field, database_id: database_id} ->
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

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )


  when_(
    ~r/^I request INNM dosage with INNM where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id} ->
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
    ~r/^I request (?<field>\w+) of the medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{field: field, database_id: database_id} ->
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

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I request (?<field>\w+) of the INNM where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{field: field, database_id: database_id} ->
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
    ~r/^I request (?<nested_field>\w+) of the (?<field>\w+) of the medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{nested_field: nested_field, field: field, database_id: database_id} ->
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

  when_(
    ~r/^I create medical program with name "(?<name>[^"]+)"$/,
    fn %{conn: conn}, %{name: name} ->
      query = """
      mutation CreateMedicalProgram($input: CreateMedicalProgramInput!) {
        createMedicalProgram(input: $input) {
          medicalProgram {
            name
          }
        }
      }
      """

      variables = %{
        input: %{
          name: name
        }
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data createMedicalProgram medicalProgram))

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I deactivate medical program where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id} ->
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

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(~r/^I suspend (?<contract_type>\w+) contract where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id, contract_type: contract_type} ->
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

      contract_type = case contract_type do
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

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
  end)

  when_(
    ~r/^I update the (?<field>\w+) with (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*})) in the program medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id, field: field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  when_(
    ~r/^I update the (?<nested_field>\w+) of the (?<field>\w+) with (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*})) in the program medication where databaseId is "(?<database_id>[^"]+)"$/,
    fn %{conn: conn}, %{database_id: database_id, field: field, nested_field: nested_field, value: value} ->
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

      {:ok, %{resp_body: resp_body, resp_entity: resp_entity}}
    end
  )

  then_(
    ~r/^event manager has event for (?<entity_type>[^"]+) with ID "(?<entity_id>[^"]+)" and consumer ID "(?<updated_by>[^"]+)"$/,
    fn state, %{entity_id: entity_id, entity_type: entity_type, updated_by: updated_by} ->
      event =
        Event
        |> where(entity_id: ^entity_id, entity_type: ^entity_type, changed_by: ^updated_by)
        |> EventManagerRepo.one()

      assert event

      {:ok, state}
  end)

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

  then_("request id should be returned", fn %{resp_body: resp_body} = state ->
      assert %{"extensions" => %{"requestId" => _}} = resp_body

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
    ~r/^the (?<field>\w+) of the requested item should be (?<value>(?:-?\d+(\.\d+)?|\w+|"[^"]+"|\[.*\]|{.*}))$/,
    fn %{resp_entity: resp_entity} = state, %{field: field, value: value} ->
      expected_value = Jason.decode!(value)
      resp_value = resp_entity[field]

      assert expected_value == resp_value

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

  def prepare_attrs(queryable \\ nil, attrs)

  def prepare_attrs(queryable, attrs) when is_map(attrs) do
    prepare_attrs(queryable, Map.to_list(attrs))
  end

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
