defmodule EHealth.Web.EmployeeRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import EHealth.SimpleFactory

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

  test "list employee requests", %{conn: conn} do
    conn = get conn, employee_request_path(conn, :index)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp, "paging")
    assert is_list(resp["data"])
  end

  test "approve employee request", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = post conn, employee_request_path(conn, :approve, id), get_headers()
    resp = json_response(conn, 200)["data"]
    assert "APPROVED" == resp["status"]
  end

  test "reject employee request", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = post conn, employee_request_path(conn, :reject, id)
    resp = json_response(conn, 200)["data"]
    assert "REJECTED" == resp["status"]
  end

  defp get_headers do
    [
      {"content-type", "application/json"},
      {"content-length", "7000"},
      {"x-consumer-id", Ecto.UUID.generate()}
    ]
  end
end
