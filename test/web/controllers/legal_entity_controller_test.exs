defmodule EHealth.Web.LegalEntityControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.MockServer

  test "create legal entity", %{conn: conn} do
    legal_entity_params = %{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => File.read!("test/data/signed_content.txt"),
    }

    conn = put conn, legal_entity_path(conn, :create_or_update), legal_entity_params
    json_response(conn, 422)
  end

  test "invalid legal entity", %{conn: conn} do
    conn = put conn, legal_entity_path(conn, :create_or_update), %{"invlid" => "data"}
    resp = json_response(conn, 422)
    assert Map.has_key?(resp, "error")
    assert resp["error"]
  end

  test "mis verify legal entity", %{conn: conn} do
      conn = put_client_id_header(conn, "296da7d2-3c5a-4f6a-b8b2-631063737271")
      conn = patch conn, legal_entity_path(conn, :mis_verify, "9b452d44-62f8-11e7-907b-a6006ad3dba0")
      assert json_response(conn, 200)["data"]["mis_verified"] == "VERIFIED"

  end

  test "mis verify legal entity which was already verified", %{conn: conn} do
    conn = put_client_id_header(conn, "296da7d2-3c5a-4f6a-b8b2-631063737271")
    conn = patch conn, legal_entity_path(conn, :mis_verify, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    json_response(conn, 409)
  end

  test "nhs verify legal entity which was already verified", %{conn: conn} do
    conn = put_client_id_header(conn, "296da7d2-3c5a-4f6a-b8b2-631063737271")
    conn = patch conn, legal_entity_path(conn, :nhs_verify, "9b452d44-62f8-11e7-907b-a6006ad3dba0")
    refute json_response(conn, 409)["data"]["nhs_verified"]
  end

  test "nhs verify legal entity", %{conn: conn} do
    conn = put_client_id_header(conn, "296da7d2-3c5a-4f6a-b8b2-631063737271")
    conn = patch conn, legal_entity_path(conn, :nhs_verify, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    assert json_response(conn, 200)["data"]["nhs_verified"]
  end

  describe "get legal entities" do
    test "without x-consumer-metadata", %{conn: conn} do
      conn = get conn, legal_entity_path(conn, :index, [edrpou: "37367387"])
      assert 401 == json_response(conn, 401)["meta"]["code"]
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      %{id: id, edrpou: edrpou} = insert(:legal_entity, id: MockServer.get_client_mis())
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :index, [edrpou: edrpou])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert Enum.all?(resp["data"], &(Map.has_key?(&1, "mis_verified")))
      assert Enum.all?(resp["data"], &(Map.has_key?(&1, "nhs_verified")))
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      %{id: id, edrpou: edrpou} = insert(:legal_entity, id: MockServer.get_client_admin())
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :index, [edrpou: edrpou])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains not MIS client_id that matches one of legal entities id",
      %{conn: conn} do
      %{id: id, edrpou: edrpou} = insert(:legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :index, [edrpou: edrpou])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains client_id that does not match legal entity id", %{conn: conn} do
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get conn, legal_entity_path(conn, :index, [legal_entity_id: id])
      resp = json_response(conn, 200)
      assert [] == resp["data"]
      assert Map.has_key?(resp, "paging")
      assert String.contains?(resp["meta"]["url"], "/legal_entities")
    end

    test "with client_id that does not exists", %{conn: conn} do
      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8603f3")
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get conn, legal_entity_path(conn, :index, [legal_entity_id: id])
      json_response(conn, 401)
    end
  end

  describe "get legal entity by id" do
    test "without x-consumer-metadata", %{conn: conn} do
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get conn, legal_entity_path(conn, :show, id)
      json_response(conn, 401)
    end

    test "with x-consumer-metadata that contains client_id that does not match legal entity id", %{conn: conn} do
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      %{id: id} = insert(:legal_entity)
      conn = get conn, legal_entity_path(conn, :show, id)
      json_response(conn, 403)
    end

    test "with x-consumer-metadata that contains invalid client_type_name", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375111")
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get conn, legal_entity_path(conn, :show, id)
      json_response(conn, 403)
    end

    test "check required legal entity fields", %{conn: conn} do
      %{id: id} = insert(:legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert "VERIFIED" == resp["data"]["mis_verified"]
      refute is_nil(resp["data"]["nhs_verified"])
      refute resp["data"]["nhs_verified"]
    end

    test "with x-consumer-metadata that contains client_id that matches legal entity id", %{conn: conn} do
      %{id: id} = insert(:legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "medical_service_provider")
      refute Map.has_key?(resp, "paging")
      assert_security_in_urgent_response(resp)
    end

    test "with x-consumer-metadata that contains MIS client_id that does not match legal entity id", %{conn: conn} do
      %{id: id} = insert(:legal_entity)
      conn = put_client_id_header(conn, MockServer.get_client_mis())
      conn = get conn, legal_entity_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "medical_service_provider")
      refute Map.has_key?(resp, "paging")
      assert_security_in_urgent_response(resp)
    end

    test "with x-consumer-metadata that contains client_id that matches inactive legal entity id", %{conn: conn} do
      %{id: id} = insert(:legal_entity, is_active: false)
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :show, id)
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end

    test "with client_id that does not exists", %{conn: conn} do
      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8603f3")
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get conn, legal_entity_path(conn, :show, id)
      json_response(conn, 401)
    end
  end

  describe "deactivate legal entity" do
    test "deactivate employee with invalid transitions condition", %{conn: conn} do
      %{id: id} = insert(:legal_entity, is_active: false)
      conn = put_client_id_header(conn, id)
      conn_resp = patch conn, legal_entity_path(conn, :deactivate, id)
      assert json_response(conn_resp, 409)["error"]["message"] == "Legal entity is not ACTIVE and cannot be updated"

      %{id: id} = insert(:legal_entity, status: "CLOSED")
      conn = put_client_id_header(conn, id)
      conn_resp = patch conn, legal_entity_path(conn, :deactivate, id)
      assert json_response(conn_resp, 409)["error"]["message"] == "Legal entity is not ACTIVE and cannot be updated"
    end

    test "deactivate legal entity with valid transitions condition", %{conn: conn} do
      %{id: id} = insert(:legal_entity)
      conn = put_client_id_header(conn, id)
      conn = patch conn, legal_entity_path(conn, :deactivate, id)

      resp = json_response(conn, 200)
      assert "CLOSED" == resp["data"]["status"]
    end
  end

  def assert_security_in_urgent_response(resp) do
    assert_urgent_field(resp, "security")
    assert Map.has_key?(resp["urgent"]["security"], "redirect_uri")
    assert Map.has_key?(resp["urgent"]["security"], "client_id")
    assert Map.has_key?(resp["urgent"]["security"], "client_secret")
  end

  def assert_urgent_field(resp, field) do
    assert Map.has_key?(resp, "urgent")
    assert Map.has_key?(resp["urgent"], field)
  end
end
