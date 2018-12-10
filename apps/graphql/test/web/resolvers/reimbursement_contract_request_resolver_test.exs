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
  end
end
