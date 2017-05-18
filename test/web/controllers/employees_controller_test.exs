defmodule EHealth.Web.EmployeesControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  test "get employees", %{conn: conn} do
    conn = get conn, employees_path(conn, :index)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp, "paging")
    assert is_list(resp["data"])
  end

  test "get employee by id", %{conn: conn} do
    conn = get conn, employees_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    assert is_map(resp["data"])
  end

end
