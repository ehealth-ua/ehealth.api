defmodule EHealth.Web.ContractControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Mox
  import EHealth.MockServer, only: [get_client_admin: 0]

  alias Ecto.UUID

  describe "show contract details" do
    test "finds contract successfully and nsh can see any contracts", %{conn: conn} do
      contract = prepare_contract()

      assert %{"data" => response_data} =
               conn
               |> put_client_id_header(get_client_admin())
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
               |> put_client_id_header(get_client_admin())
               |> get(contract_path(conn, :show, UUID.generate()))
               |> json_response(404)
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
end
