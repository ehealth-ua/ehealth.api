defmodule EHealth.Web.EmployeeRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "create employee request" do
    test "with valid params", %{conn: conn} do
      employee_request_params = File.read!("test/data/employee_request.json")

      conn = post conn, employee_request_path(conn, :create), employee_request_params
      assert json_response(conn, 200)["data"]
    end

    test "with invalid params", %{conn: conn} do
      conn = post conn, employee_request_path(conn, :create), %{"invalid" => "data"}
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
    end
  end
end
