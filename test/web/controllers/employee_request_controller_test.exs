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

  describe "list employee requests" do
    test "without filters", %{conn: conn} do
      conn = get conn, employee_request_path(conn, :index)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
    end

    test "with valid legal_entity_id filter", %{conn: conn} do
      %{data: %{"legal_entity_id" => legal_entity_id}} = fixture(:employee_request)
      conn = get conn, employee_request_path(conn, :index, %{"legal_entity_id" => legal_entity_id})
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
    end

    test "with invalid legal_entity_id filter", %{conn: conn} do
      fixture(:employee_request)
      conn = get conn, employee_request_path(conn, :index, %{"legal_entity_id" => "111"})
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 0 == length(resp["data"])
    end
  end

  test "get employee request with non-existing user", %{conn: conn} do
    employee_request = %{id: id} = fixture(:employee_request)

    conn = get conn, employee_request_path(conn, :show, id)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")

    data = Map.drop(resp["data"], ["id", "inserted_at", "updated_at", "type", "status"])

    assert Map.get(employee_request, :data) == data
    assert Map.get(employee_request, :id) == resp["data"]["id"]
    assert Map.get(employee_request, :status) == resp["data"]["status"]
    assert NaiveDateTime.to_iso8601(Map.get(employee_request, :inserted_at)) == resp["data"]["inserted_at"]
    assert NaiveDateTime.to_iso8601(Map.get(employee_request, :updated_at)) == resp["data"]["updated_at"]
    assert "employee_request" == resp["data"]["type"]
    refute Map.has_key?(resp, "urgent")
  end

  test "get employee request with existing user", %{conn: conn} do
    employee_request = %{id: id} = fixture(:employee_request, "test@user.com")

    conn = get conn, employee_request_path(conn, :show, id)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")

    data = Map.drop(resp["data"], ["id", "inserted_at", "updated_at", "type", "status"])

    assert Map.get(employee_request, :data) == data
    assert Map.get(employee_request, :id) == resp["data"]["id"]
    assert Map.get(employee_request, :status) == resp["data"]["status"]
    assert NaiveDateTime.to_iso8601(Map.get(employee_request, :inserted_at)) == resp["data"]["inserted_at"]
    assert NaiveDateTime.to_iso8601(Map.get(employee_request, :updated_at)) == resp["data"]["updated_at"]
    assert "employee_request" == resp["data"]["type"]
    assert Map.has_key?(resp, "urgent")
    assert Map.has_key?(resp["urgent"], "user_id")
    assert "userid" == resp["urgent"]["user_id"]
  end

  test "approve employee request", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = post conn, employee_request_path(conn, :approve, id)
    resp = json_response(conn, 200)["data"]
    assert "APPROVED" == resp["status"]
  end

  test "reject employee request", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = post conn, employee_request_path(conn, :reject, id)
    resp = json_response(conn, 200)["data"]
    assert "REJECTED" == resp["status"]
  end
end
