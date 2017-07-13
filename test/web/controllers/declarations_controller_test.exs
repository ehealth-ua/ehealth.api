defmodule EHealth.Web.DeclarationsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "list declarations" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375111")
      conn = get conn, declarations_path(conn, :index, [edrpou: "37367387"])
      json_response(conn, 401)
    end

    test "with x-consumer-metadata that contains MSP client_id with empty declarations list", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get conn, declarations_path(conn, :index, [edrpou: "37367387"])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert [] == resp["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id and invalid legal_entity_id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get conn, declarations_path(conn, :index, [legal_entity_id: "296da7d2-3c5a-4f6a-b8b2-631063737271"])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert [] == resp["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id", %{conn: conn} do
      legal_id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = put_client_id_header(conn, legal_id)
      conn = get conn, declarations_path(conn, :index, [edrpou: "37367387", legal_entity_id: legal_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      legal_id = "296da7d2-3c5a-4f6a-b8b2-631063737271"
      conn = put_client_id_header(conn, legal_id)
      conn = get conn, declarations_path(conn, :index, [edrpou: "37367387", legal_entity_id: legal_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 2 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      legal_id = "356b4182-f9ce-4eda-b6af-43d2de8601a1"
      conn = put_client_id_header(conn, legal_id)
      conn = get conn, declarations_path(conn, :index, [edrpou: "37367387", legal_entity_id: legal_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 3 == length(resp["data"])
    end
  end
end
