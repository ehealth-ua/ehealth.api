defmodule EHealth.Web.GlobalParameterControllerTest do
  use EHealth.Web.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all parameters on index", %{conn: conn} do
    insert(:prm, :global_parameter, parameter: "param1", value: "value1")
    insert(:prm, :global_parameter, parameter: "param2", value: "value2")
    insert(:prm, :global_parameter, parameter: "param3", value: "value3")

    conn = put_client_id_header(conn, Ecto.UUID.generate())
    conn = get conn, global_parameter_path(conn, :index)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp["data"], "param1")
    assert "value1" == resp["data"]["param1"]
    assert Map.has_key?(resp["data"], "param2")
    assert "value2" == resp["data"]["param2"]
    assert Map.has_key?(resp["data"], "param3")
    assert "value3" == resp["data"]["param3"]
  end

  describe "put parameters" do
    test "without x-consumer-id header", %{conn: conn} do
      params = %{
        "param1" => "value1"
      }

      conn = put_client_id_header(conn, "invalid")
      conn = put conn, global_parameter_path(conn, :create_or_update, params)
      resp = json_response(conn, 422)

      assert Map.has_key?(resp, "error")
      assert Map.has_key?(resp["error"], "type")
      assert "validation_failed" == resp["error"]["type"]

      assert Map.has_key?(resp["error"], "invalid")
      assert 2 == length(resp["error"]["invalid"])

      first_error = Enum.at(resp["error"]["invalid"], 0)
      assert "$.inserted_by" == first_error["entry"]
      assert 1 == length(first_error["rules"])
      rule = Enum.at(first_error["rules"], 0)
      assert "cast" == rule["rule"]

      second_error = Enum.at(resp["error"]["invalid"], 1)
      assert "$.updated_by" == second_error["entry"]
      assert 1 == length(second_error["rules"])
      rule = Enum.at(second_error["rules"], 0)
      assert "cast" == rule["rule"]
    end

    test "with x-consumer-id header", %{conn: conn} do
      insert(:prm, :global_parameter, parameter: "param1", value: "value0")

      params = %{
        "param1" => "value1",
        "param2" => "value2"
      }

      conn = put_client_id_header(conn, Ecto.UUID.generate())
      conn = put conn, global_parameter_path(conn, :create_or_update, params)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp["data"], "param1")
      assert "value1" == resp["data"]["param1"]
      assert Map.has_key?(resp["data"], "param2")
      assert "value2" == resp["data"]["param2"]
    end
  end
end
