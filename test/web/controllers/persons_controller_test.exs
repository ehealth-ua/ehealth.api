defmodule EHealth.Web.PersonsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias Ecto.UUID

  describe "get person declaration" do
    test "MSP can see own declaration", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn = get conn, persons_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200")
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert Map.has_key?(data, "person")
      assert Map.has_key?(data, "employee")
      assert Map.has_key?(data, "division")
      assert Map.has_key?(data, "legal_entity")
    end

    test "MSP can't see not own declaration", %{conn: conn} do
      conn = put_client_id_header(conn, "520e372b-8378-4722-a590-653274a6cb38")
      conn = get conn, persons_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200")
      assert 403 == json_response(conn, 403)["meta"]["code"]
    end

    test "NHS ADMIN can see any employees declarations", %{conn: conn} do
      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8601a1")
      conn = get conn, persons_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200")

      response = json_response(conn, 200)
      assert 200 == response["meta"]["code"]
      assert response["data"]["declaration_request_id"] # TODO: need more assertions on data
    end

    test "invalid declarations amount", %{conn: conn} do
      conn = put_client_id_header(conn)
      conn = get conn, persons_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375400")
      assert 400 == json_response(conn, 400)["meta"]["code"]
    end

    test "declaration not found", %{conn: conn} do
      conn = put_client_id_header(conn)
      conn = get conn, persons_path(conn, :person_declarations, UUID.generate())
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end
  end

  test "search persons", %{conn: conn} do
    conn = put_client_id_header(conn)
    conn = get conn, persons_path(conn, :search_persons)
    assert 200 == json_response(conn, 200)["meta"]["code"]
  end
end
