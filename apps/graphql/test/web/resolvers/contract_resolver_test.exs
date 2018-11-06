defmodule GraphQLWeb.ContractResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3]
  import Core.Expectations.Mithril
  import Mox

  alias Absinthe.Relay.Node
  alias Ecto.UUID
  alias Core.Contracts.Contract
  alias Core.ContractRequests.ContractRequest

  @contract_request_status_signed ContractRequest.status(:signed)
  @contract_status_terminated Contract.status(:terminated)

  @list_query """
    query ListContractsQuery($filter: ContractFilter) {
      contracts(first: 10, filter: $filter) {
        nodes {
          id
          databaseId
          status
          startDate
          nhsSigner {
            databaseId
          }
        }
      }
    }
  """

  @terminate_query """
    mutation TerminateContract($input: TerminateContractInput!) {
      terminateContract(input: $input) {
        contract {
          status
          status_reason
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
  """

  @status_reason "Period of contract is wrong"

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn = put_scope(conn, "contract:terminate contract:read")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "return all for NHS client", %{conn: conn} do
      nhs()

      for _ <- 1..2, do: insert(:prm, :contract)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contracts nodes))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)
    end

    test "return only related for MSP client", %{conn: conn} do
      msp()

      contract = for _ <- 1..2, do: insert(:prm, :contract)
      related_contract = hd(contract)

      resp_body =
        conn
        |> put_client_id(related_contract.contractor_legal_entity_id)
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert related_contract.id == hd(resp_entities)["databaseId"]
    end

    test "return forbidden error for incorrect client type", %{conn: conn} do
      mis()

      for _ <- 1..2, do: insert(:prm, :contract)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query)
        |> json_response(200)

      assert is_list(resp_body["errors"])
      assert match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, hd(resp_body["errors"]))
      assert nil == get_in(resp_body, ~w(data contracts))
    end

    test "filter by status", %{conn: conn} do
      nhs()

      for status <- ~w(VERIFIED TERMINATED), do: insert(:prm, :contract, %{status: status})

      variables = %{filter: %{status: "VERIFIED"}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert "VERIFIED" == hd(resp_entities)["status"]
    end

    test "filter by closed date interval", %{conn: conn} do
      nhs()

      today = Date.utc_today()

      for start_date <- [today, Date.add(today, -30)], do: insert(:prm, :contract, %{start_date: start_date})

      variables = %{
        filter: %{startDate: to_string(%Date.Interval{first: today, last: Date.add(today, 10)})}
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert to_string(today) == hd(resp_entities)["startDate"]
    end

    test "filter by open date interval", %{conn: conn} do
      nhs()

      today = Date.utc_today()

      for start_date <- [today, Date.add(today, -30)], do: insert(:prm, :contract, %{start_date: start_date})

      variables = %{
        filter: %{startDate: Date.Interval.to_edtf(%{first: today, last: nil})}
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert to_string(today) == hd(resp_entities)["startDate"]
    end

    test "filter by legal entity relation", %{conn: conn} do
      nhs(2)
      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_from: from, merged_to: to)
      contract_related_from = insert(:prm, :contract, %{contractor_legal_entity: from})
      contract_related_to = insert(:prm, :contract, %{contractor_legal_entity: to})

      # merged from
      variables = %{filter: %{legalEntityRelation: "MERGED_FROM"}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contracts nodes))

      refute resp_body["errors"]
      assert 1 == length(resp_entities)
      assert contract_related_from.id == hd(resp_entities)["databaseId"]

      # merged to
      variables = %{filter: %{legalEntityRelation: "MERGED_TO"}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contracts nodes))

      refute resp_body["errors"]
      assert 1 == length(resp_entities)
      assert contract_related_to.id == hd(resp_entities)["databaseId"]
    end
  end

  describe "terminate" do
    test "legal entity terminates verified contract", %{conn: conn} do
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
          :contract_request,
          status: @contract_request_status_signed,
          external_contractors: external_contractors
        )

      contract =
        insert(:prm, :contract, contract_request_id: contract_request.id, external_contractors: external_contractors)

      {resp_body, resp_entity} = call_terminate(conn, contract, contract.contractor_legal_entity_id)

      assert nil == resp_body["errors"]

      assert %{
               "status" => @contract_status_terminated,
               "status_reason" => @status_reason,
               "external_contractors" => [%{"legal_entity" => %{"database_id" => ^legal_entity_id}}]
             } = resp_entity
    end

    test "NHS terminate verified contract", %{conn: conn} do
      nhs()

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
          :contract_request,
          status: @contract_request_status_signed,
          external_contractors: external_contractors
        )

      contract =
        insert(:prm, :contract, contract_request_id: contract_request.id, external_contractors: external_contractors)

      {resp_body, resp_entity} = call_terminate(conn, contract, contract.nhs_legal_entity_id)

      assert nil == resp_body["errors"]

      assert %{
               "status" => @contract_status_terminated,
               "status_reason" => @status_reason,
               "external_contractors" => [%{"legal_entity" => %{"database_id" => ^legal_entity_id}}]
             } = resp_entity
    end

    test "NHS terminate not verified contract", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract, status: @contract_status_terminated)

      {resp_body, _} = call_terminate(conn, contract, contract.nhs_legal_entity_id)

      assert %{"errors" => [error]} = resp_body
      assert %{"extensions" => %{"code" => "CONFLICT"}} = error
    end

    test "wrong client id", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract)

      {resp_body, _} = call_terminate(conn, contract)

      assert %{"errors" => [error]} = resp_body
      assert %{"extensions" => %{"code" => "FORBIDDEN"}} = error
    end

    test "not found", %{conn: conn} do
      nhs()
      contract = insert(:prm, :contract)

      {resp_body, _} = call_terminate(conn, %{contract | id: UUID.generate()})

      assert %{"errors" => [error]} = resp_body
      assert %{"extensions" => %{"code" => "NOT_FOUND"}} = error
    end
  end

  defp call_terminate(conn, contract, client_id \\ UUID.generate()) do
    variables = %{
      input: %{
        id: Node.to_global_id("Contract", contract.id),
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
