defmodule EHealth.Web.PersonControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias Ecto.UUID
  alias EHealth.MockServer

  @moduletag :with_client_id

  describe "get person declaration" do
    test "MSP can see own declaration", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      insert(:prm, :employee, id: "7488a646-e31f-11e4-aace-600308960662", legal_entity: legal_entity)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get conn, person_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200")
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert Map.has_key?(data, "person")
      assert Map.has_key?(data, "employee")
      assert Map.has_key?(data, "division")
      assert Map.has_key?(data, "legal_entity")
    end

    test "MSP can't see not own declaration", %{conn: conn} do
      conn = get conn, person_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200")
      assert 403 == json_response(conn, 403)["meta"]["code"]
    end

    test "NHS ADMIN can see any employees declarations", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: MockServer.get_client_admin())
      insert(:prm, :employee, id: "7488a646-e31f-11e4-aace-600308960662", legal_entity: legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get conn, person_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200")

      response = json_response(conn, 200)
      assert 200 == response["meta"]["code"]
      assert response["data"]["declaration_request_id"] # TODO: need more assertions on data
    end

    test "invalid declarations amount", %{conn: conn} do
      conn = get conn, person_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375400")
      assert 400 == json_response(conn, 400)["meta"]["code"]
    end

    test "declaration not found", %{conn: conn} do
      conn = get conn, person_path(conn, :person_declarations, UUID.generate())
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end
  end

  describe "reset authentication method to NA" do

    test "success", %{conn: conn} do
      conn = patch conn, person_path(conn, :reset_authentication_method, MockServer.get_active_person())
      assert [%{"type" => "NA"}] == json_response(conn, 200)["data"]["authentication_methods"]
    end

    test "person not found", %{conn: conn} do
      conn = patch conn, person_path(conn, :reset_authentication_method, UUID.generate())
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end
  end

  test "search persons", %{conn: conn} do
    conn = get conn, person_path(conn, :search_persons)
    assert 200 == json_response(conn, 200)["meta"]["code"]
  end
end
