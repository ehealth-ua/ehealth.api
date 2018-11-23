defmodule GraphQLWeb.EmployeeResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3, insert_list: 3]
  import Core.Expectations.Mithril, only: [mis: 0, msp: 0, nhs: 0]
  import Mox, only: [verify_on_exit!: 1]

  alias Absinthe.Relay.Node
  alias Core.Employees.Employee

  @list_query """
    query ListEmployeesQuery($filter: EmployeeFilter, $orderBy: EmployeeOrderBy) {
      employees(first: 10, filter: $filter, orderBy: $orderBy) {
        nodes {
          id
          databaseId
          employeeType
          status
        }
      }
    }
  """

  @get_by_id_query """
    query GetEmployeeQuery($id: ID!) {
      employee(id: $id) {
        id
      }
    }
  """

  @employee_type_admin Employee.type(:admin)
  @employee_type_owner Employee.type(:owner)
  @employee_type_doctor Employee.type(:doctor)

  @employee_status_approved Employee.status(:approved)
  @employee_status_dismissed Employee.status(:dismissed)

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn = put_scope(conn, "employee:read")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "return all for NHS client", %{conn: conn} do
      nhs()

      insert_list(2, :prm, :employee)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)
    end

    test "return only related for MSP client", %{conn: conn} do
      msp()

      legal_entities = insert_list(2, :prm, :legal_entity)
      employees = for legal_entity <- legal_entities, do: insert(:prm, :employee, legal_entity: legal_entity)
      related_employee = hd(employees)

      resp_body =
        conn
        |> put_client_id(related_employee.legal_entity.id)
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert related_employee.id == hd(resp_entities)["databaseId"]
    end

    test "return forbidden error for incorrect client type", %{conn: conn} do
      mis()

      insert_list(2, :prm, :employee)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query)
        |> json_response(200)

      assert is_list(resp_body["errors"])
      assert match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, hd(resp_body["errors"]))
      assert nil == get_in(resp_body, ~w(data employees))
    end

    test "filter by match", %{conn: conn} do
      nhs()

      for employee_type <- [@employee_type_admin, @employee_type_owner, @employee_type_doctor] do
        insert(:prm, :employee, employee_type: employee_type)
      end

      employee_types = [@employee_type_admin, @employee_type_doctor]
      variables = %{filter: %{employeeType: employee_types}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)

      Enum.each(resp_entities, fn employee ->
        assert employee["employeeType"] in employee_types
      end)
    end

    test "filter by association", %{conn: conn} do
      nhs()

      legal_entities = for edrpou <- ["1234567890", "0987654321"], do: insert(:prm, :legal_entity, edrpou: edrpou)
      for legal_entity <- legal_entities, do: insert(:prm, :employee, legal_entity: legal_entity)

      requested_legal_entity = hd(legal_entities)

      query = """
        query ListEmployeesQuery($filter: EmployeeFilter, $orderBy: EmployeeOrderBy) {
          employees(first: 10, filter: $filter, orderBy: $orderBy) {
            nodes {
              legalEntity {
                databaseId
                edrpou
              }
            }
          }
        }
      """

      variables = %{filter: %{legalEntity: %{edrpou: requested_legal_entity.edrpou}}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert requested_legal_entity.id == hd(resp_entities)["legalEntity"]["databaseId"]
      assert requested_legal_entity.edrpou == hd(resp_entities)["legalEntity"]["edrpou"]
    end

    test "success with ordering", %{conn: conn} do
      nhs()

      for status <- [@employee_status_approved, @employee_status_dismissed] do
        insert(:prm, :employee, status: status)
      end

      variables = %{orderBy: "STATUS_ASC"}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data employees nodes))

      assert nil == resp_body["errors"]
      assert @employee_status_approved == hd(resp_entities)["status"]
    end
  end

  describe "get by id" do
    test "success for NHS client", %{conn: conn} do
      nhs()

      employee = insert(:prm, :employee)

      id = Node.to_global_id("Employee", employee.id)

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employee))

      assert nil == resp_body["errors"]
      assert id == resp_entity["id"]
    end

    test "success for correct MSP client", %{conn: conn} do
      msp()

      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity: legal_entity)

      id = Node.to_global_id("Employee", employee.id)

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id(employee.legal_entity.id)
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employee))

      assert nil == resp_body["errors"]
      assert id == resp_entity["id"]
    end

    test "return nothing for incorrect MSP client", %{conn: conn} do
      msp()

      employee = insert(:prm, :employee)

      id = Node.to_global_id("Employee", employee.id)

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employee))

      assert nil == resp_body["errors"]
      assert nil == resp_entity
    end

    test "return forbidden error for incorrect client type", %{conn: conn} do
      mis()

      employee = insert(:prm, :employee)

      id = Node.to_global_id("Employee", employee.id)

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employee))

      assert is_list(resp_body["errors"])
      assert match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, hd(resp_body["errors"]))
      assert nil == resp_entity
    end

    test "success with related entities", %{conn: conn} do
      nhs()

      party = insert(:prm, :party)
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee = insert(:prm, :employee, party: party, legal_entity: legal_entity, division: division)

      id = Node.to_global_id("Employee", employee.id)

      query = """
        query GetEmployeeWithRelatedEntitiesQuery($id: ID!) {
          employee(id: $id) {
            party {
              databaseId
            }
            division {
              databaseId
            }
            legalEntity {
              databaseId
            }
          }
        }
      """

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data employee))

      assert nil == resp_body["errors"]
      assert party.id == resp_entity["party"]["databaseId"]
      assert division.id == resp_entity["division"]["databaseId"]
      assert legal_entity.id == resp_entity["legalEntity"]["databaseId"]
    end
  end
end
