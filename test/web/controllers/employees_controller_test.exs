defmodule EHealth.Web.EmployeesControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.MockServer
  alias Ecto.UUID

  test "gets only employees that have legal_entity_id == client_id", %{conn: conn} do
    client_id = UUID.generate()
    conn = put_client_id_header(conn, client_id)
    conn = get conn, employees_path(conn, :index)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp, "paging")
    assert is_list(resp["data"])
    assert 2 == length(resp["data"])
    first = Enum.at(resp["data"], 0)
    assert client_id == first["legal_entity_id"]
    second = Enum.at(resp["data"], 1)
    assert client_id == second["legal_entity_id"]
  end

  test "get employees", %{conn: conn} do
    conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employees_path(conn, :index)
    resp = json_response(conn, 200)["data"]
    employee = List.first(resp)

    assert Map.has_key?(employee, "doctor")
    assert Map.has_key?(employee["doctor"], "id")
    refute Map.has_key?(employee["doctor"], "science_degree")
    refute Map.has_key?(employee["doctor"], "qualifications")
    refute Map.has_key?(employee["doctor"], "educations")

    refute Map.has_key?(employee, "inserted_by")
    refute Map.has_key?(employee, "updated_by")
    refute Map.has_key?(employee, "is_active")

    assert is_map(employee["party"])
    assert is_map(employee["division"])
    assert is_map(employee["legal_entity"])
  end

  test "get employees by NHS ADMIN", %{conn: conn} do
    conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8601a1")
    conn = get conn, employees_path(conn, :index)
    resp = json_response(conn, 200)["data"]
    assert 2 = length(resp)
  end

  test "get employees with client_id that does not match legal entity id", %{conn: conn} do
    conn = put_client_id_header(conn, UUID.generate())
    id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
    conn = get conn, employees_path(conn, :index, [legal_entity_id: id])
    resp = json_response(conn, 200)
    assert [] == resp["data"]
    assert Map.has_key?(resp, "paging")
    assert String.contains?(resp["meta"]["url"], "/employees")
  end

  test "search employees by tax_id" do
    tax_id = "123"
    conn = put_client_id_header(build_conn(), "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employees_path(conn, :index, [tax_id: tax_id])
    resp = json_response(conn, 200)["data"]
    assert 1 == length(resp)
    assert tax_id == hd(resp)["party"]["tax_id"]
  end

  test "search employees by invalid tax_id" do
    conn = put_client_id_header(build_conn(), "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employees_path(conn, :index, [tax_id: ""])
    resp = json_response(conn, 200)["data"]
    assert 0 == length(resp)
  end

  test "search employees by edrpou" do
    conn = put_client_id_header(build_conn(), "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employees_path(conn, :index, [edrpou: "37367387"])
    resp = json_response(conn, 200)["data"]
    assert 1 == length(resp)
  end

  test "search employees by invalid edrpou" do
    conn = put_client_id_header(build_conn(), "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employees_path(conn, :index, [edrpou: ""])
    resp = json_response(conn, 200)["data"]
    assert 0 == length(resp)
  end

  test "get employee by id", %{conn: conn} do
    conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
    resp = json_response(conn, 200)

    assert Map.has_key?(resp["data"], "party")
    assert is_map(resp["data"]["party"])

    assert Map.has_key?(resp["data"], "division")
    assert is_map(resp["data"]["division"])

    assert Map.has_key?(resp["data"], "legal_entity")
    assert is_map(resp["data"]["legal_entity"])
  end

  describe "get employee by id" do
    test "without division", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a911a")
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
      assert %{} == resp["data"]["division"]
    end

    test "with MSP token when legal_entity_id != client_id", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())
      conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      json_response(conn, 403)
    end

    test "with MIS token when legal_entity_id != client_id", %{conn: conn} do
      conn = put_client_id_header(conn, MockServer.get_client_mis())
      conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      json_response(conn, 200)
    end

    test "with ADMIN token when legal_entity_id != client_id", %{conn: conn} do
      conn = put_client_id_header(conn, MockServer.get_client_admin())
      conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      json_response(conn, 200)
    end

    test "when legal_entity_id == client_id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_map(resp["data"])
    end
  end

  describe "deactivate employee" do
    setup %{conn: conn} do
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party)
      insert(:prm, :party_user, party: party)
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity: legal_entity, party: party)

      {:ok, %{conn: conn, legal_entity: legal_entity, employee: employee}}
    end

    test "with invalid transitions condition", %{conn: conn, legal_entity: legal_entity} do
      employee = insert(:prm, :employee, legal_entity: legal_entity, status: "DEACTIVATED")
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn_resp = patch conn, employees_path(conn, :deactivate, employee.id)

      assert json_response(conn_resp, 409)["error"]["message"] == "Employee is DEACTIVATED and cannot be updated."
    end

    test "successful", %{conn: conn, employee: employee} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn = patch conn, employees_path(conn, :deactivate, employee.id)

      resp = json_response(conn, 200)
      refute resp["is_active"]
    end

    test "not found", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn = patch conn, employees_path(conn, :deactivate, UUID.generate())

      resp = json_response(conn, 404)
      refute resp["is_active"]
    end
  end

end
