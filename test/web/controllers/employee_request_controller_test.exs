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

    test "with non-existent foreign keys", %{conn: conn} do
      employee_request_params =
        "test/data/employee_request.json"
        |> File.read!()
        |> Poison.decode!()
        |> put_in(["employee_request", "legal_entity_id"], "356b4182-f9ce-4eda-b6af-43d2de8602f2")
        |> put_in(["employee_request", "division_id"], "356b4182-f9ce-4eda-b6af-43d2de8602f2")
        |> put_in(["employee_request", "employee_id"], "356b4182-f9ce-4eda-b6af-43d2de8602f2")
        |> Poison.encode!()

      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert Map.has_key?(resp["error"], "invalid")
      assert 3 == length(resp["error"]["invalid"])

      invalid_legal_entity_id =
        Enum.find(resp["error"]["invalid"], fn(x) -> Map.get(x, "entry") == "$.legal_entity_id" end)
      assert nil != invalid_legal_entity_id
      assert Map.has_key?(invalid_legal_entity_id, "rules")
      assert 1 == length(invalid_legal_entity_id["rules"])
      rule = Enum.at(invalid_legal_entity_id["rules"], 0)
      assert "does not exist" == Map.get(rule, "description")

      invalid_division_id = Enum.find(resp["error"]["invalid"], fn(x) -> Map.get(x, "entry") == "$.division_id" end)
      assert nil != invalid_division_id
      assert Map.has_key?(invalid_division_id, "rules")
      assert 1 == length(invalid_division_id["rules"])
      rule = Enum.at(invalid_division_id["rules"], 0)
      assert "does not exist" == Map.get(rule, "description")

      invalid_employee_id = Enum.find(resp["error"]["invalid"], fn(x) -> Map.get(x, "entry") == "$.employee_id" end)
      assert nil != invalid_employee_id
      assert Map.has_key?(invalid_employee_id, "rules")
      assert 1 == length(invalid_employee_id["rules"])
      rule = Enum.at(invalid_employee_id["rules"], 0)
      assert "does not exist" == Map.get(rule, "description")
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

  test "cannot approve rejected employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "REJECTED", :approve)
  end

  test "cannot approve approved employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "APPROVED", :approve)
  end

  test "reject employee request", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = post conn, employee_request_path(conn, :reject, id)
    resp = json_response(conn, 200)["data"]
    assert "REJECTED" == resp["status"]
  end

  test "cannot reject rejected employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "REJECTED", :reject)
  end

  test "cannot reject approved employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "APPROVED", :reject)
  end

  def test_invalid_status_transition(conn, init_status, action) do
    %{id: id} = employee_request("mail@example.com", init_status)

    conn = post conn, employee_request_path(conn, action, id)
    resp = json_response(conn, 409)
    assert "Employee request status is #{init_status} and cannot be updated" == resp["error"]["message"]
    assert 409 = resp["meta"]["code"]

    conn = get conn, employee_request_path(conn, :show, id)
    assert init_status == json_response(conn, 200)["data"]["status"]
  end
end
