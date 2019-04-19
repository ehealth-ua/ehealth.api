defmodule GraphQL.ContractResolverTest do
  @moduledoc false

  use GraphQL.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3]
  import Core.Expectations.Mithril
  import Mox

  alias Absinthe.Relay.Node
  alias Ecto.UUID
  alias Core.Contracts.CapitationContract
  alias Core.ContractRequests.CapitationContractRequest

  @contract_request_status_signed CapitationContractRequest.status(:signed)
  @contract_status_terminated CapitationContract.status(:terminated)

  @terminate_query """
    mutation TerminateContract($input: TerminateContractInput!) {
      terminateContract(input: $input) {
        contract {
          status
          status_reason
          reason
          ... on CapitationContract {
            external_contractors {
              legal_entity {
                id
                database_id
                name
              }
            }
          }
        }
      }
    }
  """

  @prolongate_query """
    mutation ProlongateContract($input: ProlongateContractInput!) {
      prolongateContract(input: $input) {
        contract {
          id
          endDate
        }
      }
    }
  """

  @status_reason "DEFAULT"

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn = put_scope(conn, "contract:terminate contract:read")

    {:ok, %{conn: conn}}
  end

  describe "terminate" do
    test "legal entity terminates verified contract", %{conn: conn} do
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      msp()

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      %{id: division_id} = insert(:prm, :division)

      external_contractors = [
        %{
          "divisions" => [%{"id" => division_id, "medical_service" => "PHC_SERVICES"}],
          "contract" => %{"expires_at" => to_string(Date.add(Date.utc_today(), 50))},
          "legal_entity_id" => legal_entity_id
        }
      ]

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          status: @contract_request_status_signed,
          external_contractors: external_contractors
        )

      contract =
        insert(
          :prm,
          :capitation_contract,
          contract_request_id: contract_request.id,
          external_contractors: external_contractors
        )

      {resp_body, resp_entity} = call_terminate(conn, contract, contract.contractor_legal_entity_id)

      refute resp_body["errors"]

      assert %{
               "status" => @contract_status_terminated,
               "status_reason" => @status_reason,
               "reason" => _,
               "external_contractors" => [%{"legal_entity" => %{"database_id" => ^legal_entity_id}}]
             } = resp_entity
    end

    test "NHS terminate verified contract", %{conn: conn} do
      nhs()
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      %{id: division_id} = insert(:prm, :division)

      external_contractors = [
        %{
          "divisions" => [%{"id" => division_id, "medical_service" => "PHC_SERVICES"}],
          "contract" => %{"expires_at" => to_string(Date.add(Date.utc_today(), 50))},
          "legal_entity_id" => legal_entity_id
        }
      ]

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          status: @contract_request_status_signed,
          external_contractors: external_contractors
        )

      contract =
        insert(
          :prm,
          :capitation_contract,
          contract_request_id: contract_request.id,
          external_contractors: external_contractors
        )

      {resp_body, resp_entity} = call_terminate(conn, contract, contract.nhs_legal_entity_id)

      refute resp_body["errors"]

      assert %{
               "status" => @contract_status_terminated,
               "status_reason" => @status_reason,
               "external_contractors" => [%{"legal_entity" => %{"database_id" => ^legal_entity_id}}]
             } = resp_entity
    end

    test "success terminate reimbursement contract by NHS", %{conn: conn} do
      nhs()
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      contract_request = insert(:il, :reimbursement_contract_request, status: @contract_request_status_signed)
      contract = insert(:prm, :reimbursement_contract, contract_request_id: contract_request.id)

      {resp_body, resp_entity} = call_terminate(conn, contract, contract.nhs_legal_entity_id, "ReimbursementContract")

      refute resp_body["errors"]
      assert %{"status" => @contract_status_terminated, "status_reason" => @status_reason} = resp_entity
    end

    test "NHS terminate not verified contract", %{conn: conn} do
      nhs()
      contract = insert(:prm, :capitation_contract, status: @contract_status_terminated)

      {resp_body, _} = call_terminate(conn, contract, contract.nhs_legal_entity_id)

      assert %{"errors" => [error]} = resp_body
      assert %{"extensions" => %{"code" => "CONFLICT"}} = error
    end

    test "wrong client id", %{conn: conn} do
      nhs()
      contract = insert(:prm, :capitation_contract)

      {resp_body, _} = call_terminate(conn, contract)

      assert %{"errors" => [error]} = resp_body
      assert %{"extensions" => %{"code" => "FORBIDDEN"}} = error
    end

    test "not found", %{conn: conn} do
      nhs()
      contract = insert(:prm, :capitation_contract)

      {resp_body, _} = call_terminate(conn, %{contract | id: UUID.generate()})

      assert %{"errors" => [error]} = resp_body
      assert %{"extensions" => %{"code" => "NOT_FOUND"}} = error
    end
  end

  describe "prolongate contract" do
    test "success", %{conn: conn} do
      nhs()

      legal_entity = insert(:prm, :legal_entity)
      contractor_legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, is_active: true, merged_from: contractor_legal_entity)

      contract =
        insert(
          :prm,
          :capitation_contract,
          nhs_legal_entity: legal_entity,
          contractor_legal_entity: contractor_legal_entity
        )

      end_date = Date.utc_today() |> Date.add(23) |> to_string()

      variables = %{
        input: %{
          id: Node.to_global_id("CapitationContract", contract.id),
          end_date: end_date
        }
      }

      resp_body =
        conn
        |> put_scope("contract:update")
        |> put_consumer_id()
        |> put_client_id(legal_entity.id)
        |> post_query(@prolongate_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data prolongateContract contract))

      refute resp_body["errors"]
      assert %{"endDate" => ^end_date} = resp_entity
    end
  end

  defp call_terminate(conn, contract, client_id \\ UUID.generate(), contract_node \\ "CapitationContract") do
    variables = %{
      input: %{
        id: Node.to_global_id(contract_node, contract.id),
        status_reason: @status_reason
      }
    }

    resp_body =
      conn
      |> put_consumer_id()
      |> put_client_id(client_id)
      |> post_query(@terminate_query, variables)
      |> json_response(200)

    resp_entity = get_in(resp_body, ~w(data terminateContract contract))

    {resp_body, resp_entity}
  end
end
