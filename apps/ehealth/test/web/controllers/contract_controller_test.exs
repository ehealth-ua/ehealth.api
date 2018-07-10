defmodule EHealth.Web.ContractControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import EHealth.Expectations.Signature
  import Mox
  alias EHealth.Contracts.Contract
  alias Ecto.UUID
  import Mox

  describe "show contract" do
    test "finds contract successfully and nhs can see any contracts", %{conn: conn} do
      nhs(2)

      expect(MediaStorageMock, :create_signed_url, 4, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://url.com/#{id}/#{resource_name}"}}}
      end)

      contract_request = insert(:il, :contract_request)
      contract = insert(:prm, :contract, contract_request_id: contract_request.id, status: "SIGNED")

      assert response =
               %{"data" => response_data} =
               conn
               |> put_client_id_header(UUID.generate())
               |> get(contract_path(conn, :show, contract.id))
               |> json_response(200)

      assert response_data["id"] == contract.id
      assert length(response["urgent"]["documents"]) == 3

      Enum.each(response["urgent"]["documents"], fn urgent_data ->
        assert Map.has_key?(urgent_data, "type")
        assert(Map.has_key?(urgent_data, "url"))
      end)
    end

    test "ensure TOKENS_TYPES_PERSONAL has access to own contracts", %{conn: conn} do
      msp()
      contractor_legal_entity = insert(:prm, :legal_entity)
      contract_request = insert(:il, :contract_request)

      contract =
        insert(
          :prm,
          :contract,
          contractor_legal_entity_id: contractor_legal_entity.id,
          contract_request_id: contract_request.id
        )

      assert %{"data" => response_data} =
               conn
               |> put_client_id_header(contractor_legal_entity.id)
               |> get(contract_path(conn, :show, contract.id))
               |> json_response(200)

      assert response_data["contractor_legal_entity"]["id"] == contractor_legal_entity.id
    end

    test "ensure TOKENS_TYPES_PERSONAL has no access to other contracts", %{conn: conn} do
      msp()
      contractor_legal_entity = insert(:prm, :legal_entity)
      contract = insert(:prm, :contract)

      assert %{"error" => %{"type" => "forbidden", "message" => _}} =
               conn
               |> put_client_id_header(contractor_legal_entity.id)
               |> get(contract_path(conn, :show, contract.id))
               |> json_response(403)
    end

    test "not found", %{conn: conn} do
      nhs()

      assert %{"error" => %{"type" => "not_found"}} =
               conn
               |> put_client_id_header(UUID.generate())
               |> get(contract_path(conn, :show, UUID.generate()))
               |> json_response(404)
    end
  end

  describe "contract list" do
    test "validating search params: ignore invalid search params", %{conn: conn} do
      nhs()
      insert(:prm, :contract)
      insert(:prm, :contract)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), %{created_by: UUID.generate()})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 2
    end

    test "validating search params: edrpou is defined, contractor_legal_entity_id is not defined", %{conn: conn} do
      nhs()
      edrpou = "5432345432"
      contractor_legal_entity = insert(:prm, :legal_entity, edrpou: edrpou)
      insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id)
      insert(:prm, :contract)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), %{edrpou: edrpou})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou is not defined, contractor_legal_entity_id is defined", %{conn: conn} do
      nhs()
      contractor_legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id)
      insert(:prm, :contract)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), %{contractor_legal_entity_id: contractor_legal_entity.id})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou and contractor_legal_entity_id are defined and belong to the same legal entity",
         %{conn: conn} do
      nhs()
      edrpou = "5432345432"
      contractor_legal_entity = insert(:prm, :legal_entity, edrpou: edrpou)
      insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id)
      insert(:prm, :contract)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), %{edrpou: edrpou, contractor_legal_entity_id: contractor_legal_entity.id})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou and contractor_legal_entity_id are defined and do not belong to the same legal entity",
         %{conn: conn} do
      nhs()
      edrpou = "5432345432"
      contractor_legal_entity = insert(:prm, :legal_entity)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), %{edrpou: edrpou, contractor_legal_entity_id: contractor_legal_entity.id})

      resp = json_response(conn, 200)
      assert resp["data"] == []

      assert %{
               "page_number" => 1,
               "total_entries" => 0,
               "total_pages" => 1
             } = resp["paging"]
    end

    test "validating search params: page_size by default", %{conn: conn} do
      nhs()

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index))

      resp = json_response(conn, 200)

      assert %{
               "page_size" => 50,
               "page_number" => 1,
               "total_entries" => 0,
               "total_pages" => 1
             } = resp["paging"]
    end

    test "validating search params: page_size defined by user", %{conn: conn} do
      nhs()
      page_size = 100

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), %{page_size: page_size})

      resp = json_response(conn, 200)

      assert %{
               "page_size" => ^page_size,
               "page_number" => 1,
               "total_entries" => 0,
               "total_pages" => 1
             } = resp["paging"]
    end

    test "success contract list for NHS admin user", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract, is_suspended: true)
      insert(:prm, :contract)

      params = %{
        id: contract.id,
        contractor_owner_id: contract.contractor_owner_id,
        nhs_signer_id: contract.nhs_signer_id,
        status: contract.status,
        is_suspended: true,
        date_from_start_date: contract.start_date,
        date_to_start_date: contract.start_date,
        date_from_end_date: contract.end_date,
        date_to_end_date: contract.end_date,
        contract_number: contract.contract_number
      }

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
    end

    test "success contract list for NHS admin user from dates only", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract)
      insert(:prm, :contract, start_date: ~D[2017-01-01])

      params = %{
        date_from_start_date: contract.start_date,
        date_from_end_date: contract.end_date
      }

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
    end

    test "success contract list for NHS admin user to dates only", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract, end_date: ~D[2017-01-01])
      insert(:prm, :contract)

      params = %{
        date_to_start_date: contract.start_date,
        date_to_end_date: contract.end_date
      }

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :index), params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
    end

    test "success contract list for non-NHS admin user", %{conn: conn} do
      msp()
      contractor_legal_entity = insert(:prm, :legal_entity)
      contract = insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id, is_suspended: true)
      insert(:prm, :contract)

      params = %{
        id: contract.id,
        contractor_owner_id: contract.contractor_owner_id,
        nhs_signer_id: contract.nhs_signer_id,
        status: contract.status,
        is_suspended: true,
        date_from_start_date: contract.start_date,
        date_to_start_date: contract.start_date,
        date_from_end_date: contract.end_date,
        date_to_end_date: contract.end_date,
        contract_number: contract.contract_number
      }

      conn =
        conn
        |> put_client_id_header(contractor_legal_entity.id)
        |> get(contract_path(conn, :index), params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
    end

    test "success filtering by nhs_signer_id", %{conn: conn} do
      msp()
      contractor_legal_entity = insert(:prm, :legal_entity)
      contract_in = insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id)
      contract_out = insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id)

      params = %{nhs_signer_id: contract_in.nhs_signer_id}

      conn =
        conn
        |> put_client_id_header(contractor_legal_entity.id)
        |> get(contract_path(conn, :index), params)

      assert resp = json_response(conn, 200)["data"]

      contract_ids = Enum.map(resp, fn item -> Map.get(item, "id") end)
      assert contract_in.id in contract_ids
      refute contract_out.id in contract_ids
    end
  end

  describe "update employees" do
    test "contract_employee not found", %{conn: conn} do
      nhs()

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> patch(contract_path(conn, :update, UUID.generate()))

      assert json_response(conn, 404)
    end

    test "failed to decode signed content", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract)

      params = %{
        "signed_content" => Jason.encode!(%{}),
        "signed_content_encoding" => "base64"
      }

      invalid_signed_content()

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> patch(contract_path(conn, :update, contract.id), params)

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "rules" => [%{"rule" => "invalid", "params" => [], "description" => "Not a base64 string"}],
                   "entry_type" => "json_data_property",
                   "entry" => "$.signed_content"
                 }
               ]
             } = resp["error"]
    end

    test "invalid drfo", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract)
      division = insert(:prm, :division)
      employee = insert(:prm, :employee)
      employee_id = employee.id
      party_user = insert(:prm, :party_user)

      content = %{
        "employee_id" => employee_id,
        "division_id" => division.id,
        "declaration_limit" => 10,
        "staff_units" => 0.33
      }

      params = %{
        "signed_content" =>
          content
          |> Jason.encode!()
          |> Base.encode64(),
        "signed_content_encoding" => "base64"
      }

      drfo_signed_content(content, nil)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> put_consumer_id_header(party_user.user_id)
        |> patch(contract_path(conn, :update, contract.id), params)

      assert resp = json_response(conn, 422)

      assert %{
               "message" => "Invalid drfo"
             } = resp["error"]
    end

    test "invalid status", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract, status: Contract.status(:terminated))
      division = insert(:prm, :division)
      employee = insert(:prm, :employee)
      employee_id = employee.id
      insert(:prm, :contract_division, contract_id: contract.id, division_id: division.id)
      party_user = insert(:prm, :party_user)

      content = %{
        "employee_id" => employee_id,
        "division_id" => division.id,
        "declaration_limit" => 10,
        "staff_units" => 0.33
      }

      params = %{
        "signed_content" =>
          content
          |> Jason.encode!()
          |> Base.encode64(),
        "signed_content_encoding" => "base64"
      }

      drfo_signed_content(content, party_user.party.tax_id)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> put_consumer_id_header(party_user.user_id)
        |> Plug.Conn.put_req_header("drfo", party_user.party.tax_id)
        |> patch(contract_path(conn, :update, contract.id), params)

      assert resp = json_response(conn, 409)
      assert "Not active contract can't be updated" == resp["error"]["message"]
    end

    test "succes update employee", %{conn: conn} do
      nhs()
      contract_request = insert(:il, :contract_request)
      contract = insert(:prm, :contract, contract_request_id: contract_request.id)
      legal_entity = insert(:prm, :legal_entity, id: contract.contractor_legal_entity_id)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee = insert(:prm, :employee, legal_entity: legal_entity)
      employee_id = employee.id
      insert(:prm, :contract_division, contract_id: contract.id, division_id: division.id)

      insert(
        :prm,
        :contract_employee,
        contract_id: contract.id,
        employee_id: employee_id,
        division_id: division.id,
        declaration_limit: 2000
      )

      party_user = insert(:prm, :party_user)

      content = %{
        "employee_id" => employee_id,
        "division_id" => division.id,
        "declaration_limit" => 10,
        "staff_units" => 0.33
      }

      params = %{
        "signed_content" =>
          content
          |> Jason.encode!()
          |> Base.encode64(),
        "signed_content_encoding" => "base64"
      }

      drfo_signed_content(content, party_user.party.tax_id)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> put_consumer_id_header(party_user.user_id)
        |> Plug.Conn.put_req_header("drfo", party_user.party.tax_id)
        |> patch(contract_path(conn, :update, contract.id), params)

      assert resp = json_response(conn, 200)

      assert [%{"employee" => %{"id" => ^employee_id}, "declaration_limit" => 10, "staff_units" => 0.33}] =
               resp["data"]["contractor_employee_divisions"]
    end

    test "succes insert employees", %{conn: conn} do
      nhs()
      contract_request = insert(:il, :contract_request)
      contract = insert(:prm, :contract, contract_request_id: contract_request.id)
      legal_entity = insert(:prm, :legal_entity, id: contract.contractor_legal_entity_id)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee = insert(:prm, :employee, legal_entity: legal_entity)
      employee_id = employee.id
      insert(:prm, :contract_division, contract_id: contract.id, division_id: division.id)
      party_user = insert(:prm, :party_user)

      content = %{
        "employee_id" => employee_id,
        "division_id" => division.id,
        "declaration_limit" => 10,
        "staff_units" => 0.33
      }

      params = %{
        "signed_content" =>
          content
          |> Jason.encode!()
          |> Base.encode64(),
        "signed_content_encoding" => "base64"
      }

      drfo_signed_content(content, party_user.party.tax_id)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> put_consumer_id_header(party_user.user_id)
        |> Plug.Conn.put_req_header("drfo", party_user.party.tax_id)
        |> patch(contract_path(conn, :update, contract.id), params)

      assert resp = json_response(conn, 200)

      assert [%{"employee" => %{"id" => ^employee_id}, "declaration_limit" => 10, "staff_units" => 0.33}] =
               resp["data"]["contractor_employee_divisions"]
    end
  end

  describe "get printout_form" do
    test "success get printout_form", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      printout_content = "<html></html>"

      legal_entity_signer = insert(:prm, :legal_entity, edrpou: "10002000")

      expect(MediaStorageMock, :get_signed_content, 2, fn _ ->
        {:ok, %{body: ""}}
      end)

      %{id: contract_request_id} =
        contract_request =
        insert(
          :il,
          :contract_request,
          printout_content: printout_content
        )

      %{id: contract_id} =
        insert(
          :prm,
          :contract,
          status: Contract.status(:verified),
          contract_request_id: contract_request_id
        )

      content =
        contract_request
        |> Jason.encode!()
        |> Jason.decode!()

      edrpou_signed_content(content, legal_entity_signer.edrpou)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_path(conn, :printout_content, contract_id))

      assert resp = json_response(conn, 200)
      assert %{"id" => contract_id, "printout_content" => printout_content} == resp["data"]
    end
  end
end
