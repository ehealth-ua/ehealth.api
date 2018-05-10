defmodule EHealth.Web.ContractControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Mox
  import EHealth.MockServer, only: [get_client_nhs: 0]

  alias Ecto.UUID
  alias Scrivener.Page

  describe "show contract details" do
    test "finds contract successfully and nsh can see any contracts", %{conn: conn} do
      contract = prepare_contract()

      assert %{"data" => response_data} =
               conn
               |> put_client_id_header(get_client_nhs())
               |> get(contract_path(conn, :show, contract["id"]))
               |> json_response(200)

      assert response_data["id"] == contract["id"]

      # todo: add assertion with json schema
    end

    test "ensure TOKENS_TYPES_PERSONAL has access to own contracts", %{conn: conn} do
      contractor_legal_entity = insert(:prm, :legal_entity)
      contract = prepare_contract(contractor_legal_entity_id: contractor_legal_entity.id)

      assert %{"data" => response_data} =
               conn
               |> put_client_id_header(contractor_legal_entity.id)
               |> get(contract_path(conn, :show, contract["id"]))
               |> json_response(200)

      assert response_data["contractor_legal_entity"]["id"] == contractor_legal_entity.id
    end

    test "ensure TOKENS_TYPES_PERSONAL has no access to other contracts", %{conn: conn} do
      contractor_legal_entity = insert(:prm, :legal_entity)
      contract = prepare_contract(contractor_legal_entity_id: UUID.generate())

      assert %{"error" => %{"type" => "forbidden", "message" => _}} =
               conn
               |> put_client_id_header(contractor_legal_entity.id)
               |> get(contract_path(conn, :show, contract["id"]))
               |> json_response(403)
    end

    test "not found", %{conn: conn} do
      expect(OPSMock, :get_contract, fn _, _ ->
        {:error,
         %{
           "error" => %{"type" => "not_found"},
           "meta" => %{
             "code" => 404,
             "type" => "object"
           }
         }}
      end)

      assert %{"error" => %{"type" => "not_found"}} =
               conn
               |> put_client_id_header(get_client_nhs())
               |> get(contract_path(conn, :show, UUID.generate()))
               |> json_response(404)
    end
  end

  describe "contract list" do
    setup %{conn: conn} do
      search_params = %{
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        contractor_legal_entity_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        edrpou: "5432345432",
        contractor_owner_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        nhs_signer_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        status: "VERIFIED",
        is_suspended: true,
        date_from_start_date: "2018-01-01",
        date_to_start_date: "2019-01-01",
        date_from_end_date: "2018-01-01",
        date_to_end_date: "2019-01-01",
        contract_number: "0000-9EAX-XT7X-3115",
        page: 1,
        page_size: 100
      }

      {:ok, %{conn: conn, search_params: search_params}}
    end

    test "validating search params: ignore invalid search params", %{conn: conn} do
      prepare_contracts([%{}, %{}])

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{created_by: UUID.generate()})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 2
    end

    test "validating search params: edrpou is defined, contractor_legal_entity_id is not defined", %{
      conn: conn,
      search_params: %{edrpou: edrpou}
    } do
      contractor_legal_entity = insert(:prm, :legal_entity, edrpou: edrpou)
      prepare_contracts([%{contractor_legal_entity_id: contractor_legal_entity.id}, %{}])

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{edrpou: edrpou})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou is not defined, contractor_legal_entity_id is defined", %{
      conn: conn,
      search_params: %{contractor_legal_entity_id: contractor_legal_entity_id}
    } do
      contractor_legal_entity = insert(:prm, :legal_entity, id: contractor_legal_entity_id)
      prepare_contracts([%{contractor_legal_entity_id: contractor_legal_entity.id}, %{}])

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{contractor_legal_entity_id: contractor_legal_entity_id})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou and contractor_legal_entity_id are defined and belong to the same legal entity",
         %{conn: conn, search_params: %{edrpou: edrpou, contractor_legal_entity_id: contractor_legal_entity_id}} do
      contractor_legal_entity = insert(:prm, :legal_entity, id: contractor_legal_entity_id, edrpou: edrpou)
      prepare_contracts([%{contractor_legal_entity_id: contractor_legal_entity.id}, %{}])

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{edrpou: edrpou, contractor_legal_entity_id: contractor_legal_entity_id})

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
      assert resp |> hd() |> Map.get("contractor_legal_entity_id") == contractor_legal_entity.id
    end

    test "validating search params: edrpou and contractor_legal_entity_id are defined and do not belong to the same legal entity",
         %{conn: conn, search_params: %{edrpou: edrpou, contractor_legal_entity_id: contractor_legal_entity_id}} do
      insert(:prm, :legal_entity, id: contractor_legal_entity_id)

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), %{edrpou: edrpou, contractor_legal_entity_id: contractor_legal_entity_id})

      resp = json_response(conn, 200)
      assert resp["data"] == []

      assert %{
               "page_number" => 1,
               "total_entries" => 0,
               "total_pages" => 1
             } = resp["paging"]
    end

    test "validating search params: page_size by default", %{conn: conn} do
      prepare_contracts([])

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
      prepare_contracts([], page_size)

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

    test "success contract list for NHS admin user", %{conn: conn, search_params: search_params} do
      search_params =
        search_params
        |> Map.delete(:edrpou)
        |> Map.delete(:contractor_legal_entity_id)

      prepare_contracts([%{}, %{}])

      conn =
        conn
        |> put_client_id_header(get_client_nhs())
        |> get(contract_path(conn, :index), search_params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 2
    end

    test "success contract list for non-NHS admin user", %{conn: conn, search_params: search_params} do
      search_params =
        search_params
        |> Map.delete(:edrpou)
        |> Map.delete(:contractor_legal_entity_id)

      contractor_legal_entity = insert(:prm, :legal_entity)
      prepare_contracts([%{contractor_legal_entity_id: contractor_legal_entity.id}, %{}])

      conn =
        conn
        |> put_client_id_header(contractor_legal_entity.id)
        |> get(contract_path(conn, :index), search_params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1
    end
  end

  defp prepare_contract(params \\ []) do
    contract_request = insert(:il, :contract_request)
    contract_params = [contract_request_id: contract_request.id] ++ params

    # string_params_for converts NaiveDateTime to map instead of string, so encode, decode
    contract = build(:contract, contract_params) |> Poison.encode!() |> Poison.decode!()

    expect(OPSMock, :get_contract, fn _, _ ->
      {:ok, %{"data" => contract}}
    end)

    contract
  end

  defp prepare_contracts(params, page_size \\ 50) when is_list(params) do
    data =
      Enum.map(params, fn item_params ->
        build(:contract, item_params)
        |> Poison.encode!()
        |> Poison.decode!()
      end)

    expect(OPSMock, :get_contracts, fn search_params, _ ->
      contractor_legal_entity_id = Map.get(search_params, :contractor_legal_entity_id)

      data =
        if is_nil(contractor_legal_entity_id) do
          data
        else
          Enum.filter(data, fn item -> Map.get(item, "contractor_legal_entity_id") == contractor_legal_entity_id end)
        end

      {:ok,
       %{
         "data" => data,
         "meta" => %{"code" => 200},
         "paging" => %Page{
           entries: data,
           page_number: 1,
           page_size: page_size,
           total_entries: length(data),
           total_pages: 1
         }
       }}
    end)
  end
end
