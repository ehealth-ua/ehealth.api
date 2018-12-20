defmodule GraphQLWeb.ReimbursementContractRequestResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories
  import Core.Expectations.Mithril
  import Mox

  alias Absinthe.Relay.Node

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn = put_scope(conn, "contract_request:read contract_request:update")

    {:ok, %{conn: conn}}
  end

  describe "get by id" do
    test "success with attached documents", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://example.com/#{id}/#{resource_name}"}}}
      end)

      contract_request = insert(:il, :reimbursement_contract_request)

      id = Node.to_global_id("ReimbursementContractRequest", contract_request.id)

      query = """
        query GetContractRequestWithAttachedDocumentsQuery($id: ID!) {
          reimbursementContractRequest(id: $id) {
            attachedDocuments {
              type
              url
            }
          }
        }
      """

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContractRequest attachedDocuments))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)

      Enum.each(resp_entities, fn document ->
        assert Map.has_key?(document, "type")
        assert Map.has_key?(document, "url")
      end)
    end

    test "building not required", %{conn: conn} do
      nhs()

      address = %{
        type: "REGISTRATION",
        country: "UA",
        area: "Житомирська",
        region: "Бердичівський",
        settlement: "Київ",
        settlement_type: "CITY",
        settlement_id: UUID.generate(),
        street_type: "STREET",
        street: "вул. Ніжинська",
        building: nil,
        apartment: "23",
        zip: "02090"
      }

      legal_entity = insert(:prm, :legal_entity, addresses: [address, Map.put(address, :building, "")])
      contract_request = insert(:il, :reimbursement_contract_request, contractor_legal_entity_id: legal_entity.id)

      id = Node.to_global_id("ReimbursementContractRequest", contract_request.id)

      query = """
        query GetContractRequestWithAttachedDocumentsQuery($id: ID!) {
          reimbursementContractRequest(id: $id) {
            contractorLegalEntity {
              addresses {
                building
              }
            }
          }
        }
      """

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      assert nil == resp_body["errors"]

      addresses = get_in(resp_body, ~w(data reimbursementContractRequest contractorLegalEntity addresses))
      assert [%{"building" => nil}, %{"building" => ""}] == addresses
    end
  end
end
