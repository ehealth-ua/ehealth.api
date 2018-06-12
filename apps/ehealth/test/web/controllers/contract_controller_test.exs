defmodule EHealth.Web.ContractControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import EHealth.MockServer, only: [get_client_nhs: 0]
  alias Ecto.UUID

  describe "show contract" do
    test "finds contract successfully and nhs can see any contracts", %{conn: conn} do
      contract_request = insert(:il, :contract_request)
      contract = insert(:prm, :contract, contract_request_id: contract_request.id)

      assert %{"data" => response_data} =
               conn
               |> put_client_id_header(get_client_nhs())
               |> get(contract_path(conn, :show, contract.id))
               |> json_response(200)

      assert response_data["id"] == contract.id
    end

    test "ensure TOKENS_TYPES_PERSONAL has access to own contracts", %{conn: conn} do
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
      contractor_legal_entity = insert(:prm, :legal_entity)
      contract = insert(:prm, :contract)

      assert %{"error" => %{"type" => "forbidden", "message" => _}} =
               conn
               |> put_client_id_header(contractor_legal_entity.id)
               |> get(contract_path(conn, :show, contract.id))
               |> json_response(403)
    end

    test "not found", %{conn: conn} do
      assert %{"error" => %{"type" => "not_found"}} =
               conn
               |> put_client_id_header(get_client_nhs())
               |> get(contract_path(conn, :show, UUID.generate()))
               |> json_response(404)
    end
  end

  describe "contract list" do
    test "validating search params: ignore invalid search params", %{conn: conn} do
      insert(:prm, :contract)
      insert(:prm, :contract)

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{created_by: UUID.generate()})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 2
    end

    test "validating search params: edrpou is defined, contractor_legal_entity_id is not defined", %{conn: conn} do
      edrpou = "5432345432"
      contractor_legal_entity = insert(:prm, :legal_entity, edrpou: edrpou)
      insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id)
      insert(:prm, :contract)

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{edrpou: edrpou})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou is not defined, contractor_legal_entity_id is defined", %{conn: conn} do
      contractor_legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id)
      insert(:prm, :contract)

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{contractor_legal_entity_id: contractor_legal_entity.id})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou and contractor_legal_entity_id are defined and belong to the same legal entity",
         %{conn: conn} do
      edrpou = "5432345432"
      contractor_legal_entity = insert(:prm, :legal_entity, edrpou: edrpou)
      insert(:prm, :contract, contractor_legal_entity_id: contractor_legal_entity.id)
      insert(:prm, :contract)

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{edrpou: edrpou, contractor_legal_entity_id: contractor_legal_entity.id})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou and contractor_legal_entity_id are defined and do not belong to the same legal entity",
         %{conn: conn} do
      edrpou = "5432345432"
      contractor_legal_entity = insert(:prm, :legal_entity)

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
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
      conn =
        conn
        |> put_client_id_header(get_client_nhs())
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
      page_size = 100

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
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
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
    end

    test "success contract list for NHS admin user from dates only", %{conn: conn} do
      contract = insert(:prm, :contract)
      insert(:prm, :contract, start_date: ~D[2017-01-01])

      params = %{
        date_from_start_date: contract.start_date,
        date_from_end_date: contract.end_date
      }

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
    end

    test "success contract list for NHS admin user to dates only", %{conn: conn} do
      contract = insert(:prm, :contract, end_date: ~D[2017-01-01])
      insert(:prm, :contract)

      params = %{
        date_to_start_date: contract.start_date,
        date_to_end_date: contract.end_date
      }

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
    end

    test "success contract list for non-NHS admin user", %{conn: conn} do
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
  end

  describe "suspend contracts" do
    test "success", %{conn: conn} do
      insert(:prm, :contract)
      %{id: id1} = insert(:prm, :contract)
      %{id: id2} = insert(:prm, :contract)
      %{id: id3} = insert(:prm, :contract, is_suspended: true)
      params = [ids: Enum.join([id1, id2, id3, UUID.generate()], ",")]

      assert %{"suspended" => 3} ==
               conn
               |> put_client_id_header(get_client_nhs())
               |> patch(contract_path(conn, :suspend), params)
               |> json_response(200)
               |> Map.get("data")
    end

    test "invalid ids", %{conn: conn} do
      assert conn
             |> put_client_id_header(get_client_nhs())
             |> patch(contract_path(conn, :suspend), ids: "invalid,uuid")
             |> json_response(422)
    end
  end
end
