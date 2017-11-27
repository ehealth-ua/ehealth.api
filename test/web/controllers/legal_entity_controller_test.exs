defmodule EHealth.Web.LegalEntityControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.MockServer
  alias EHealth.Employees.Employee
  alias EHealth.PRMRepo
  alias EHealth.LegalEntities.LegalEntity

  test "invalid legal entity", %{conn: conn} do
    conn = put conn, legal_entity_path(conn, :create_or_update), %{"invlid" => "data"}
    resp = json_response(conn, 422)
    assert Map.has_key?(resp, "error")
    assert resp["error"]
  end

  test "mis verify legal entity", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity, mis_verified: "NOT_VERIFIED")
    conn = put_client_id_header(conn, id)
    conn = patch conn, legal_entity_path(conn, :mis_verify, id)
    assert json_response(conn, 200)["data"]["mis_verified"] == "VERIFIED"
  end

  test "mis verify legal entity which was already verified", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity, mis_verified: "VERIFIED")
    conn = put_client_id_header(conn, id)
    conn = patch conn, legal_entity_path(conn, :mis_verify, id)
    assert json_response(conn, 409)
  end

  test "nhs verify legal entity which was already verified", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity, nhs_verified: true)
    conn = put_client_id_header(conn, id)
    conn = patch conn, legal_entity_path(conn, :nhs_verify, id)
    refute json_response(conn, 409)["data"]["nhs_verified"]
  end

  test "nhs verify legal entity", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity, nhs_verified: false)
    conn = put_client_id_header(conn, id)
    conn = patch conn, legal_entity_path(conn, :nhs_verify, id)
    assert json_response(conn, 200)["data"]["nhs_verified"]
  end

  describe "get legal entities" do
    test "without x-consumer-metadata", %{conn: conn} do
      conn = get conn, legal_entity_path(conn, :index, [edrpou: "37367387"])
      assert 401 == json_response(conn, 401)["meta"]["code"]
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      %{id: id, edrpou: edrpou} = insert(:prm, :legal_entity, id: MockServer.get_client_mis())
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :index, [edrpou: edrpou])

      schema =
        "test/data/legal_entity/list_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
      assert Enum.all?(resp["data"], &(Map.has_key?(&1, "mis_verified")))
      assert Enum.all?(resp["data"], &(Map.has_key?(&1, "nhs_verified")))
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      %{id: id, edrpou: edrpou} = insert(:prm, :legal_entity, id: MockServer.get_client_admin())
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :index, [edrpou: edrpou])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains not MIS client_id that matches one of legal entities id",
      %{conn: conn} do
      insert(:prm, :legal_entity)
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :index)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type msp", %{conn: conn} do
      insert(:prm, :legal_entity)
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :index, type: LegalEntity.type(:msp))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type pharmacy", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, type: LegalEntity.type(:pharmacy))
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :index, type: LegalEntity.type(:pharmacy))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
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
      %{id: id} = insert(:prm, :legal_entity)
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
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert "VERIFIED" == resp["data"]["mis_verified"]
      refute is_nil(resp["data"]["nhs_verified"])
      refute resp["data"]["nhs_verified"]
    end

    test "with x-consumer-metadata that contains client_id that matches legal entity id", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get conn, legal_entity_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "medical_service_provider")
      refute Map.has_key?(resp, "paging")
      assert_security_in_urgent_response(resp)
    end

    test "with x-consumer-metadata that contains MIS client_id that does not match legal entity id", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, MockServer.get_client_mis())
      conn = get conn, legal_entity_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "medical_service_provider")
      refute Map.has_key?(resp, "paging")
      assert_security_in_urgent_response(resp)
    end

    test "with x-consumer-metadata that contains client_id that matches inactive legal entity id", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, is_active: false)
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
      %{id: id} = insert(:prm, :legal_entity, is_active: false)
      conn = put_client_id_header(conn, id)
      conn_resp = patch conn, legal_entity_path(conn, :deactivate, id)
      assert json_response(conn_resp, 409)["error"]["message"] == "Legal entity is not ACTIVE and cannot be updated"

      %{id: id} = insert(:prm, :legal_entity, status: "CLOSED")
      conn = put_client_id_header(conn, id)
      conn_resp = patch conn, legal_entity_path(conn, :deactivate, id)
      assert json_response(conn_resp, 409)["error"]["message"] == "Legal entity is not ACTIVE and cannot be updated"
    end

    test "deactivate legal entity with valid transitions condition", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = patch conn, legal_entity_path(conn, :deactivate, id)

      resp = json_response(conn, 200)
      assert "CLOSED" == resp["data"]["status"]
    end

    test "deactivate legal entity with OWNER employee", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee,
        employee_type: Employee.type(:owner),
        legal_entity_id: id
      )
      assert employee.is_active
      conn = put_client_id_header(conn, id)
      conn = patch conn, legal_entity_path(conn, :deactivate, id)

      resp = json_response(conn, 200)
      assert "CLOSED" == resp["data"]["status"]
      employee = PRMRepo.one(Employee)
      refute employee.is_active
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
