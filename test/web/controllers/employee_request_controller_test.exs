defmodule EHealth.Web.EmployeeRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import EHealth.SimpleFactory

  @moduletag :with_client_id

  describe "create employee request" do
    test "with valid params and empty x-consumer-metadata", %{conn: conn} do
      conn = delete_client_id_header(conn)
      employee_request_params = File.read!("test/data/employee_request.json")
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      json_response(conn, 401)
    end

    test "with valid params and x-consumer-metadata that contains invalid client_id", %{conn: conn} do
      employee_request_params = File.read!("test/data/employee_request.json")
      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      json_response(conn, 422)
    end

    test "with valid params and x-consumer-metadata that contains valid client_id", %{conn: conn} do
      employee_request_params = File.read!("test/data/employee_request.json")
      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 200)["data"]
      refute Map.has_key?(resp, "type")
    end

    test "with doctor attribute for employee_type admin", %{conn: conn} do
      employee_request_params =
        "test/data/employee_request.json"
        |> File.read!()
        |> Poison.decode!()
        |> put_in(["employee_request", "employee_type"], "ADMIN")

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post conn, employee_request_path(conn, :create), employee_request_params

      json_response(conn, 422)
    end

    test "with invalid params", %{conn: conn} do
      conn = post conn, employee_request_path(conn, :create), %{"employee_request" => %{"invalid" => "data"}}
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
    end

    test "with non-existent foreign keys", %{conn: conn} do
      employee_request_params =
        "test/data/employee_request.json"
        |> File.read!()
        |> Poison.decode!()
        |> put_in(["employee_request", "division_id"], "356b4182-f9ce-4eda-b6af-43d2de8602f2")
        |> put_in(["employee_request", "employee_id"], "356b4182-f9ce-4eda-b6af-43d2de8602f2")
        |> Poison.encode!()

      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
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

    test "with invaid tax id", %{conn: conn} do
      employee_request_params =
        "test/data/employee_request.json"
        |> File.read!()
        |> Poison.decode!()
        |> put_in(["employee_request", "party", "tax_id"], "1111111111")
        |> Poison.encode!()

      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert Map.has_key?(resp["error"], "invalid")
      assert 1 == length(resp["error"]["invalid"])

      invalid_tax_id = Enum.at(resp["error"]["invalid"], 0)
      assert Map.has_key?(invalid_tax_id, "rules")
      assert 1 == length(invalid_tax_id["rules"])
      rule = Enum.at(invalid_tax_id["rules"], 0)
      assert "invalid tax_id value" == Map.get(rule, "description")
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

    test "with valid client_id in metadata", %{conn: conn} do
      %{data: %{"legal_entity_id" => legal_entity_id}} = fixture(:employee_request)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, employee_request_path(conn, :index)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
    end

    test "with invalid client_id in metadata", %{conn: conn} do
      fixture(:employee_request)
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      conn = get conn, employee_request_path(conn, :index)
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
    assert Map.has_key?(resp, "urgent")
    assert Map.has_key?(resp["urgent"], "user_id")
    assert "userid" == resp["urgent"]["user_id"]
  end

  test "create user by employee request", %{conn: conn} do
    %{id: id} = fixture(:employee_request, "test@user.com")
    conn = post conn, employee_request_path(conn, :create_user, id), %{"password" => "123"}
    resp = json_response(conn, 201)
    assert Map.has_key?(resp["data"], "email")
  end

  test "create user by employee request invalid params", %{conn: conn} do
    %{id: id} = fixture(:employee_request, "test@user.com")
    conn = post conn, employee_request_path(conn, :create_user, id), %{"passwords" => "123"}
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "create user by employee request invalid id", %{conn: conn} do
    assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
      post conn, employee_request_path(conn, :create_user, Ecto.UUID.generate()), %{"password" => "pw"}
    end
  end

  test "can approve employee request if email maches", %{conn: conn} do
    %{id: id} = fixture(:employee_request, "mis_bot_1493831618@user.com", "NEW", "OWNER")

    conn = post conn, employee_request_path(conn, :approve, id)
    resp = json_response(conn, 200)["data"]
    assert "APPROVED" == resp["status"]
  end

  test "cannot approve employee request if email doesnot match", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = post conn, employee_request_path(conn, :approve, id)
    json_response(conn, 403)
  end

  test "cannot approve rejected employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "REJECTED", :approve)
  end

  test "cannot approve approved employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "APPROVED", :approve)
  end

  test "cannot approve employee request if you didn't create it'", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = put_client_id_header(conn, Ecto.UUID.generate())
    conn = post conn, employee_request_path(conn, :approve, id)
    json_response(conn, 403)
  end

  test "can approve employee request if you created it'", %{conn: conn} do
    %{id: id, data: data} = fixture(:employee_request, "mis_bot_1493831618@user.com")

    conn = put_client_id_header(conn, Map.get(data, "legal_entity_id"))
    conn = post conn, employee_request_path(conn, :approve, id)
    resp = json_response(conn, 200)["data"]
    assert "APPROVED" == resp["status"]
  end

  test "can reject employee request if email matches", %{conn: conn} do
    %{id: id} = fixture(:employee_request, "mis_bot_1493831618@user.com")

    conn = post conn, employee_request_path(conn, :reject, id)
    resp = json_response(conn, 200)["data"]
    assert "REJECTED" == resp["status"]
  end

  test "cannot reject employee request if email doesnot match", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = post conn, employee_request_path(conn, :reject, id)
    json_response(conn, 403)
  end

  test "cannot reject rejected employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "REJECTED", :reject)
  end

  test "cannot reject approved employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "APPROVED", :reject)
  end

  test "cannot reject employee request if you didn't create it'", %{conn: conn} do
    %{id: id} = fixture(:employee_request)

    conn = put_client_id_header(conn, Ecto.UUID.generate())
    conn = post conn, employee_request_path(conn, :reject, id)
    json_response(conn, 403)
  end

  test "can reject employee request if you created it'", %{conn: conn} do
    %{id: id, data: data} = fixture(:employee_request, "mis_bot_1493831618@user.com")

    conn = put_client_id_header(conn, Map.get(data, "legal_entity_id"))
    conn = post conn, employee_request_path(conn, :reject, id)
    resp = json_response(conn, 200)["data"]
    assert "REJECTED" == resp["status"]
  end

  def test_invalid_status_transition(conn, init_status, action) do
    %{id: id} = employee_request("mis_bot_1493831618@user.com", init_status)

    conn_resp = post conn, employee_request_path(conn, action, id)
    resp = json_response(conn_resp, 409)
    assert "Employee request status is #{init_status} and cannot be updated" == resp["error"]["message"]
    assert 409 = resp["meta"]["code"]

    conn = get conn, employee_request_path(conn, :show, id)
    assert init_status == json_response(conn, 200)["data"]["status"]
  end
end
