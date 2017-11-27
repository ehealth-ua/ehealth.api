defmodule EHealth.Web.EmployeesControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.MockServer
  alias EHealth.Employees.Employee
  alias EHealth.Parties.Party
  alias Ecto.UUID
  alias EHealth.PRMRepo

  test "gets only employees that have legal_entity_id == client_id", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity, id: UUID.generate())
    %{id: legal_entity_id} = legal_entity
    party1 = insert(:prm, :party, tax_id: "2222222225")
    party2 = insert(:prm, :party, tax_id: "2222222224")
    insert(:prm, :employee, legal_entity: legal_entity, party: party1)
    insert(:prm, :employee,
      legal_entity: legal_entity,
      employee_type: Employee.type(:pharmacist),
      party: party2
    )
    conn = put_client_id_header(conn, legal_entity_id)
    conn = get conn, employee_path(conn, :index)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp, "paging")
    assert is_list(resp["data"])
    assert 2 == length(resp["data"])
    first = Enum.at(resp["data"], 0)
    assert legal_entity_id == first["legal_entity"]["id"]
    second = Enum.at(resp["data"], 1)
    assert legal_entity_id == second["legal_entity"]["id"]
    assert Enum.any?(resp["data"], &(Map.has_key?(&1, "doctor")))
    assert Enum.any?(resp["data"], &(Map.has_key?(&1, "pharmacist")))
  end

  test "filter employees by invalid party_id", %{conn: conn} do
    %{id: legal_entity_id} = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = put_client_id_header(conn, legal_entity_id)
    conn = get conn, employee_path(conn, :index, party_id: "invalid")
    assert json_response(conn, 422)
  end

  test "get employees", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    %{id: legal_entity_id} = legal_entity
    party = insert(:prm, :party)
    insert(:prm, :employee, legal_entity: legal_entity, party: party)
    conn = put_client_id_header(conn, legal_entity_id)
    conn = get conn, employee_path(conn, :index)

    schema =
      "test/data/employee/list_response_schema.json"
      |> File.read!()
      |> Poison.decode!()

    resp = json_response(conn, 200)["data"]
    :ok = NExJsonSchema.Validator.validate(schema, resp)

    employee = List.first(resp)
    refute Map.has_key?(employee["doctor"], "science_degree")
    refute Map.has_key?(employee["doctor"], "qualifications")
    refute Map.has_key?(employee["doctor"], "educations")

    refute Map.has_key?(employee, "inserted_by")
    refute Map.has_key?(employee, "updated_by")
    refute Map.has_key?(employee, "is_active")
  end

  test "get employees by NHS ADMIN", %{conn: conn} do
    party1 = insert(:prm, :party, tax_id: "2222222225")
    party2 = insert(:prm, :party, tax_id: "2222222224")
    legal_entity = insert(:prm, :legal_entity, id: MockServer.get_client_admin())
    insert(:prm, :employee, legal_entity: legal_entity, party: party1)
    insert(:prm, :employee, legal_entity: legal_entity, party: party2)
    conn = put_client_id_header(conn, legal_entity.id)
    conn = get conn, employee_path(conn, :index)
    resp = json_response(conn, 200)["data"]
    assert 2 = length(resp)
  end

  test "get employees with client_id that does not match legal entity id", %{conn: conn} do
    conn = put_client_id_header(conn, UUID.generate())
    id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
    conn = get conn, employee_path(conn, :index, [legal_entity_id: id])
    resp = json_response(conn, 200)
    assert [] == resp["data"]
    assert Map.has_key?(resp, "paging")
    assert String.contains?(resp["meta"]["url"], "/employees")
  end

  test "search employees by tax_id" do
    tax_id = "123"
    party = insert(:prm, :party, tax_id: tax_id)
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :employee, party: party, legal_entity: legal_entity)
    conn = put_client_id_header(build_conn(), legal_entity.id)
    conn = get conn, employee_path(conn, :index, [tax_id: tax_id])
    resp = json_response(conn, 200)["data"]
    assert 1 == length(resp)
    party = PRMRepo.get(Party, resp |> hd() |> get_in(["party", "id"]))
    assert tax_id == party.tax_id
  end

  test "search employees by invalid tax_id" do
    conn = put_client_id_header(build_conn(), "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employee_path(conn, :index, [tax_id: ""])
    resp = json_response(conn, 200)["data"]
    assert 0 == length(resp)
  end

  test "search employees by edrpou" do
    edrpou = "37367387"
    legal_entity = insert(:prm, :legal_entity, edrpou: edrpou)
    insert(:prm, :employee, legal_entity: legal_entity)
    conn = put_client_id_header(build_conn(), legal_entity.id)
    conn = get conn, employee_path(conn, :index, [edrpou: edrpou])
    resp = json_response(conn, 200)["data"]
    assert 1 == length(resp)
  end

  test "search employees by invalid edrpou" do
    conn = put_client_id_header(build_conn(), "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employee_path(conn, :index, [edrpou: ""])
    resp = json_response(conn, 200)["data"]
    assert 0 == length(resp)
  end

  describe "get employee by id" do
    test "with party, division, legal_entity", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      party1 = insert(:prm, :party, tax_id: "2222222225")
      employee = insert(:prm, :employee, legal_entity: legal_entity, party: party1)

      conn = put_client_id_header(conn, legal_entity.id)
      conn1 = get conn, employee_path(conn, :show, employee.id)

      schema =
        "test/data/employee/show_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      resp = json_response(conn1, 200)["data"]
      :ok = NExJsonSchema.Validator.validate(schema, resp)

      party2 = insert(:prm, :party, tax_id: "2222222224")
      employee = insert(:prm, :employee,
        legal_entity: legal_entity,
        employee_type: Employee.type(:pharmacist),
        party: party2
      )

      conn2 = get conn, employee_path(conn, :show, employee.id)

      schema =
        "test/data/employee/show_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      resp = json_response(conn2, 200)["data"]
      :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "without division", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      employee = insert(:prm, :employee, legal_entity: legal_entity, division: nil)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get conn, employee_path(conn, :show, employee.id)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp["data"], "party")
      assert Map.has_key?(resp["data"], "legal_entity")

      refute Map.has_key?(resp["data"]["party"], "data")
      refute Map.has_key?(resp["data"]["party"], "updated_by")
      refute Map.has_key?(resp["data"]["party"], "created_by")

      refute Map.has_key?(resp["data"]["legal_entity"], "data")
      refute Map.has_key?(resp["data"]["legal_entity"], "updated_by")
      refute Map.has_key?(resp["data"]["legal_entity"], "created_by")

      refute Map.has_key?(resp["data"], "division_id")
      assert nil == resp["data"]["division"]
    end

    test "with MSP token when legal_entity_id != client_id", %{conn: conn} do
      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, UUID.generate())
      conn = get conn, employee_path(conn, :show, employee.id)
      json_response(conn, 403)
    end

    test "with MIS token when legal_entity_id != client_id", %{conn: conn} do
      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, MockServer.get_client_mis())
      conn = get conn, employee_path(conn, :show, employee.id)
      json_response(conn, 200)
    end

    test "with ADMIN token when legal_entity_id != client_id", %{conn: conn} do
      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, MockServer.get_client_admin())
      conn = get conn, employee_path(conn, :show, employee.id)
      json_response(conn, 200)
    end

    test "when legal_entity_id == client_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      employee = insert(:prm, :employee, legal_entity: legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get conn, employee_path(conn, :show, employee.id)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_map(resp["data"])
    end
  end

  describe "deactivate employee" do
    setup %{conn: conn} do
      party = insert(:prm, :party, tax_id: "2222222225")
      insert(:prm, :party_user, party: party)
      insert(:prm, :party_user, party: party)
      legal_entity = insert(:prm, :legal_entity)
      doctor = insert(:prm, :employee, legal_entity: legal_entity, party: party)
      pharmacist = insert(:prm, :employee,
        legal_entity: legal_entity,
        party: party,
        employee_type: Employee.type(:pharmacist)
      )

      {:ok, %{conn: conn, legal_entity: legal_entity, doctor: doctor, pharmacist: pharmacist}}
    end

    test "with invalid transitions condition", %{conn: conn, legal_entity: legal_entity} do
      employee = insert(:prm, :employee, legal_entity: legal_entity, status: "DEACTIVATED")
      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch conn, employee_path(conn, :deactivate, employee.id)

      assert json_response(conn_resp, 409)["error"]["message"] == "Employee is DEACTIVATED and cannot be updated."
    end

    test "can't deactivate OWNER", %{conn: conn, legal_entity: legal_entity} do
      employee = insert(:prm, :employee,
        legal_entity: legal_entity,
        employee_type: Employee.type(:owner)
      )
      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch conn, employee_path(conn, :deactivate, employee.id)

      assert json_response(conn_resp, 409)["error"]["message"] == "Owner can’t be deactivated"
    end

    test "can't deactivate PHARMACY OWNER", %{conn: conn, legal_entity: legal_entity} do
      employee = insert(:prm, :employee,
        legal_entity: legal_entity,
        employee_type: Employee.type(:pharmacy_owner)
      )
      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch conn, employee_path(conn, :deactivate, employee.id)

      assert json_response(conn_resp, 409)["error"]["message"] == "Pharmacy owner can’t be deactivated"
    end

    test "successful doctor", %{conn: conn, doctor: doctor, legal_entity: legal_entity} do
      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch conn, employee_path(conn, :deactivate, doctor.id)

      resp = json_response(conn, 200)
      refute resp["is_active"]
    end

    test "successful pharmacist", %{conn: conn, pharmacist: pharmacist, legal_entity: legal_entity} do
      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch conn, employee_path(conn, :deactivate, pharmacist.id)

      resp = json_response(conn, 200)
      refute resp["is_active"]
    end

    test "not found", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")

      assert_raise Ecto.NoResultsError, fn ->
        patch conn, employee_path(conn, :deactivate, UUID.generate())
      end
    end
  end
end
