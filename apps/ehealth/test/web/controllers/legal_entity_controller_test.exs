defmodule EHealth.Web.LegalEntityControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false
  import Mox
  import EHealth.Expectations.Signature
  alias Ecto.UUID
  alias EHealth.Employees.Employee
  alias EHealth.PRMRepo
  alias EHealth.LegalEntities.LegalEntity

  setup :verify_on_exit!
  setup :set_mox_global

  defp insert_dictionaries do
    insert(:il, :dictionary_phone_type)
    insert(:il, :dictionary_address_type)
    insert(:il, :dictionary_document_type)
  end

  defp get_legal_entity_data do
    "test/data/legal_entity.json"
    |> File.read!()
    |> Jason.decode!()
  end

  defp sign_legal_entity(request_params) do
    %{
      "signed_legal_entity_request" => Base.encode64(Jason.encode!(request_params)),
      "signed_content_encoding" => "base64"
    }
  end

  describe "create or update legal entity" do
    test "invalid legal entity", %{conn: conn} do
      conn = put(conn, legal_entity_path(conn, :create_or_update), %{"invalid" => "data"})
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
    end

    test "create legal entity with wrong type", %{conn: conn} do
      insert_dictionaries()
      invalid_legal_entity_type = "MIS"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => invalid_legal_entity_type})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)

      resp = json_response(conn, 422)
      assert resp
      assert resp["error"]["message"] == "Only legal_entity with type MSP or Pharmacy could be created"
    end

    test "create legal entity", %{conn: conn} do
      get_client_type_by_name(UUID.generate())

      expect(MithrilMock, :put_client, fn params, _ ->
        {:ok, %{"data" => Map.put(params, "secret", "secret")}}
      end)

      validate_addresses()
      render_template()

      insert_dictionaries()
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)

      resp = json_response(conn, 200)
      assert resp
    end
  end

  describe "contract suspend on update legal entity" do
    test "contract suspend on change legal entity name", %{conn: conn} do
      get_client_type_by_name(UUID.generate(), 2)
      put_client(2)
      validate_addresses(2)
      render_template(2)

      insert_dictionaries()
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => "MSP"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      consumer_id = UUID.generate()
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      conn1 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", consumer_id)
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)

      id = json_response(conn1, 200)["data"]["id"]
      %{id: contract_id} = insert(:prm, :contract, contractor_legal_entity_id: id)
      legal_entity_params = Map.put(legal_entity_params, "name", "Institute of medical researches ISMT")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      conn2 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)

      resp2 = json_response(conn2, 200)
      assert resp2

      assert %{"data" => response_data} =
               conn
               |> put_client_id_header(nhs())
               |> get(contract_path(conn, :show, contract_id))
               |> json_response(200)

      assert response_data["is_suspended"] == true
    end

    test "contract suspend on change status", %{conn: conn} do
      get_client_type_by_name(UUID.generate(), 2)
      put_client(2)
      validate_addresses(2)
      render_template(2)

      insert_dictionaries()
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => "MSP"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      consumer_id = UUID.generate()
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      conn1 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", consumer_id)
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)

      id = json_response(conn1, 200)["data"]["id"]
      %{id: contract_id} = insert(:prm, :contract, contractor_legal_entity_id: id)
      legal_entity_params = Map.put(legal_entity_params, "status", "CLOSED")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      conn2 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)

      resp2 = json_response(conn2, 200)
      assert resp2

      assert %{"data" => response_data} =
               conn
               |> put_client_id_header(nhs())
               |> get(contract_path(conn, :show, contract_id))
               |> json_response(200)

      assert response_data["is_suspended"] == true
    end

    test "contract suspend on change address", %{conn: conn} do
      get_client_type_by_name(UUID.generate(), 2)
      put_client(2)
      validate_addresses(2)
      render_template(2)

      insert_dictionaries()
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => "MSP"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      consumer_id = UUID.generate()
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      conn1 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", consumer_id)
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)

      id = json_response(conn1, 200)["data"]["id"]

      %{id: contract_id} = insert(:prm, :contract, contractor_legal_entity_id: id)

      [addres | addresses] = legal_entity_params["addresses"]
      addresses = [%{addres | "apartment" => "42/12"} | addresses]
      legal_entity_params = Map.put(legal_entity_params, "addresses", addresses)
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      conn2 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)

      resp2 = json_response(conn2, 200)
      assert resp2

      assert %{"data" => response_data} =
               conn
               |> put_client_id_header(nhs())
               |> get(contract_path(conn, :show, contract_id))
               |> json_response(200)

      assert response_data["is_suspended"] == true
    end
  end

  describe "verify legal entities" do
    test "mis verify legal entity", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, mis_verified: "NOT_VERIFIED")
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :mis_verify, id))
      assert json_response(conn, 200)["data"]["mis_verified"] == "VERIFIED"
    end

    test "mis verify legal entity which was already verified", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, mis_verified: "VERIFIED")
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :mis_verify, id))
      assert json_response(conn, 409)
    end

    test "nhs verify legal entity which was already verified", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, nhs_verified: true)
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :nhs_verify, id))
      refute json_response(conn, 409)["data"]["nhs_verified"]
    end

    test "nhs verify legal entity", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, nhs_verified: false)
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :nhs_verify, id))
      assert json_response(conn, 200)["data"]["nhs_verified"]
    end
  end

  describe "get legal entities" do
    setup %{conn: conn} do
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)
      %{conn: conn}
    end

    test "without x-consumer-metadata", %{conn: conn} do
      conn = get(conn, legal_entity_path(conn, :index, edrpou: "37367387"))
      assert 401 == json_response(conn, 401)["meta"]["code"]
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      msp()
      %{id: id, edrpou: edrpou} = insert(:prm, :legal_entity)

      resp =
        conn
        |> put_client_id_header(id)
        |> get(legal_entity_path(conn, :index, edrpou: edrpou))
        |> json_response(200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert_list_response_schema(resp["data"], "legal_entity")
      assert Enum.all?(resp["data"], &Map.has_key?(&1, "mis_verified"))
      assert Enum.all?(resp["data"], &Map.has_key?(&1, "nhs_verified"))
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      nhs()
      %{id: id, edrpou: edrpou} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :index, edrpou: edrpou))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
    end

    test "with not MIS client_id that matches one of legal entities id", %{conn: conn} do
      msp()
      insert(:prm, :legal_entity)
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type msp", %{conn: conn} do
      msp()
      insert(:prm, :legal_entity)
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :index, type: LegalEntity.type(:msp)))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type pharmacy", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity, type: LegalEntity.type(:pharmacy))
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :index, type: LegalEntity.type(:pharmacy)))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type status and settlement_id", %{conn: conn} do
      msp()
      settlement_id = Ecto.UUID.generate()

      %{id: id} =
        insert(
          :prm,
          :legal_entity,
          status: LegalEntity.status(:active),
          addresses: [
            %{settlement_id: settlement_id}
          ]
        )

      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :index, status: "ACTIVE", settlement_id: settlement_id))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "with x-consumer-metadata that contains client_id that does not match legal entity id", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, legal_entity_path(conn, :index, legal_entity_id: id))
      resp = json_response(conn, 200)
      assert [] == resp["data"]
      assert Map.has_key?(resp, "paging")
      assert String.contains?(resp["meta"]["url"], "/legal_entities")
    end

    test "with client_id that does not exists", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:error, :access_denied} end)
      conn = put_client_id_header(conn, UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, legal_entity_path(conn, :index, legal_entity_id: id))
      json_response(conn, 401)
    end
  end

  describe "get legal entity by id" do
    test "without x-consumer-metadata", %{conn: conn} do
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, legal_entity_path(conn, :show, id))
      json_response(conn, 401)
    end

    test "with x-consumer-metadata that contains client_id that does not match legal entity id", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      %{id: id} = insert(:prm, :legal_entity)
      conn = get(conn, legal_entity_path(conn, :show, id))
      json_response(conn, 403)
    end

    test "with x-consumer-metadata that contains invalid client_type_name", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:ok, nil} end)
      conn = put_client_id_header(conn, UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, legal_entity_path(conn, :show, id))
      json_response(conn, 403)
    end

    test "check required legal entity fields", %{conn: conn} do
      msp()
      get_client()
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert "VERIFIED" == resp["data"]["mis_verified"]
      refute is_nil(resp["data"]["nhs_verified"])
      refute resp["data"]["nhs_verified"]
    end

    test "with x-consumer-metadata that contains client_id that matches legal entity id", %{conn: conn} do
      msp()
      get_client()
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "medical_service_provider")
      assert Map.has_key?(resp["data"], "website")
      assert Map.has_key?(resp["data"], "archive")
      assert Map.has_key?(resp["data"], "beneficiary")
      assert Map.has_key?(resp["data"], "receiver_funds_code")
      refute Map.has_key?(resp, "paging")
      assert_security_in_urgent_response(resp)
    end

    test "with x-consumer-metadata that contains MIS client_id that does not match legal entity id", %{conn: conn} do
      mis()
      get_client()
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "medical_service_provider")
      refute Map.has_key?(resp, "paging")
      assert_security_in_urgent_response(resp)
    end

    test "with x-consumer-metadata that contains client_id that matches inactive legal entity id", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity, is_active: false)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :show, id))
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end

    test "with client_id that does not exists", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:error, :access_denied} end)
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, legal_entity_path(conn, :show, UUID.generate()))
      json_response(conn, 401)
    end
  end

  describe "deactivate legal entity" do
    test "deactivate employee with invalid transitions condition", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, is_active: false)
      conn = put_client_id_header(conn, id)
      conn_resp = patch(conn, legal_entity_path(conn, :deactivate, id))
      assert json_response(conn_resp, 409)["error"]["message"] == "Legal entity is not ACTIVE and cannot be updated"

      %{id: id} = insert(:prm, :legal_entity, status: "CLOSED")
      conn = put_client_id_header(conn, id)
      conn_resp = patch(conn, legal_entity_path(conn, :deactivate, id))
      assert json_response(conn_resp, 409)["error"]["message"] == "Legal entity is not ACTIVE and cannot be updated"
    end

    test "deactivate legal entity with valid transitions condition", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :deactivate, id))

      resp = json_response(conn, 200)
      assert "CLOSED" == resp["data"]["status"]
      assert Map.has_key?(resp["data"], "website")
      assert Map.has_key?(resp["data"], "archive")
      assert Map.has_key?(resp["data"], "beneficiary")
      assert Map.has_key?(resp["data"], "receiver_funds_code")
    end

    test "deactivate legal entity with OWNER employee", %{conn: conn} do
      expect(OPSMock, :terminate_employee_declarations, fn _id, _user_id, "auto_employee_deactivate", "", _headers ->
        {:ok, %{}}
      end)

      %{id: id} = insert(:prm, :legal_entity)

      employee =
        insert(
          :prm,
          :employee,
          employee_type: Employee.type(:owner),
          legal_entity_id: id
        )

      assert employee.is_active

      resp =
        conn
        |> put_client_id_header(id)
        |> patch(legal_entity_path(conn, :deactivate, id))
        |> json_response(200)

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

  defp get_client_type_by_name(id, n \\ 1) do
    expect(MithrilMock, :get_client_type_by_name, n, fn _, _ ->
      {:ok, %{"data" => [%{"id" => id}]}}
    end)
  end

  defp render_template(n \\ 1) do
    expect(ManMock, :render_template, n, fn _, _ ->
      {:ok, "<html></html>"}
    end)
  end

  defp validate_addresses(n \\ 1) do
    expect(UAddressesMock, :validate_addresses, n, fn _, _ ->
      {:ok, %{"data" => %{}}}
    end)
  end
end
