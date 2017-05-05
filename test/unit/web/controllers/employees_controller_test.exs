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

end
