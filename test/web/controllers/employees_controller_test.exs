defmodule EHealth.Web.EmployeesControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  test "gets only employees that have legal_entity_id == client_id", %{conn: conn} do
    client_id = Ecto.UUID.generate()
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

  test "get employee by id", %{conn: conn} do
    conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
    resp = json_response(conn, 200)
    assert Map.has_key?(resp["data"], "party")
    assert Map.has_key?(resp["data"], "division")
    assert Map.has_key?(resp["data"], "legal_entity_id")
  end

  test "cannot get employee by id when legal_entity_id != client_id", %{conn: conn} do
    conn = put_client_id_header(conn, Ecto.UUID.generate())
    conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
    json_response(conn, 404)
  end

  test "can get employee by id when legal_entity_id == client_id", %{conn: conn} do
    conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    assert is_map(resp["data"])
  end
end
