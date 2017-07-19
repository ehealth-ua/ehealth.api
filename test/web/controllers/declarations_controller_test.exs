defmodule EHealth.Web.DeclarationsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.MockServer, only: [get_client_admin: 0, get_client_mis: 0, get_client_nil: 0]

  @declaration_id "156b4182-f9ce-4eda-b6af-43d2de8601z2"

  describe "list declarations" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      conn = put_client_id_header(conn, get_client_nil())
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
      conn = get conn, declarations_path(conn, :index, [legal_entity_id: legal_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      Enum.each(resp["data"], &assert_declaration_expanded_fields(&1))
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      legal_id = "296da7d2-3c5a-4f6a-b8b2-631063737271"
      conn = put_client_id_header(conn, legal_id)
      conn = get conn, declarations_path(conn, :index, [legal_entity_id: legal_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 2 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      legal_id = get_client_admin()
      conn = put_client_id_header(conn, legal_id)
      conn = get conn, declarations_path(conn, :index, [legal_entity_id: legal_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 3 == length(resp["data"])
      Enum.each(resp["data"], &assert_declaration_expanded_fields(&1))
    end
  end

  describe "declaration by id" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      conn = put_client_id_header(conn, get_client_nil())
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      json_response(conn, 401)
    end

    test "with x-consumer-metadata that contains MSP client_id with undefined declaration id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get conn, declarations_path(conn, :show, "226b4182-f9ce-4eda-b6af-43d2de8600a0")
      json_response(conn, 404)
    end

    test "with x-consumer-metadata that contains MSP client_id with invalid legal_entity_id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375000")
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      json_response(conn, 403)
    end

    test "with x-consumer-metadata that contains MSP client_id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      data = json_response(conn, 200)["data"]
      assert_declaration_expanded_fields(data)
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      conn = put_client_id_header(conn, get_client_mis())
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert @declaration_id == data["id"]
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      conn = put_client_id_header(conn, get_client_admin())
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert @declaration_id == data["id"]
    end
  end

  def assert_declaration_expanded_fields(declaration) do
    fields = ~W(person employee division legal_entity)
    assert is_map(declaration)
    Enum.each(fields, fn (field) ->
      assert Map.has_key?(declaration, field), "Expected field #{field} not present"
      assert is_map(declaration[field]), "Expected that field #{field} is map"
      assert Map.has_key?(declaration[field], "id"), "Expected field #{field}.id not present"
      refute Map.has_key?(declaration, field <> "_id"), "Field #{field}_id should be not present"
    end)
  end
end
