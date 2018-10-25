defmodule GraphQLWeb.ContractRequestResolverTest do
  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3]
  import Core.Expectations.Mithril, only: [mis: 0, msp: 0, nhs: 0]
  import Mox, only: [verify_on_exit!: 1]

  alias Absinthe.Relay.Node

  @list_query """
    query ListContractRequestsQuery($filter: ContractRequestFilter) {
      contractRequests(first: 10, filter: $filter) {
        nodes {
          id
          databaseId
          status
          startDate
        }
      }
    }
  """

  @get_by_id_query """
    query GetContractRequestQuery($id: ID!) {
      contractRequest(id: $id) {
        id
      }
    }
  """

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn = put_scope(conn, "contract_request:read contract_request:write")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "return all for NHS client", %{conn: conn} do
      nhs()

      for _ <- 1..2, do: insert(:il, :contract_request)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)
    end

    test "return only related for MSP client", %{conn: conn} do
      msp()

      contract_requests = for _ <- 1..2, do: insert(:il, :contract_request)
      related_contract_request = hd(contract_requests)

      resp_body =
        conn
        |> put_client_id(related_contract_request.contractor_legal_entity_id)
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert related_contract_request.id == hd(resp_entities)["databaseId"]
    end

    test "return forbidden error for incorrect client type", %{conn: conn} do
      mis()

      for _ <- 1..2, do: insert(:il, :contract_request)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query)
        |> json_response(200)

      assert is_list(resp_body["errors"])
      assert match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, hd(resp_body["errors"]))
      assert nil == get_in(resp_body, ~w(data contractRequests))
    end

    test "filter by match", %{conn: conn} do
      nhs()

      for status <- ~w(NEW APPROWED), do: insert(:il, :contract_request, %{status: status})

      variables = %{filter: %{status: "NEW"}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert "NEW" == hd(resp_entities)["status"]
    end
  end

  describe "get by id" do
    test "success for NHS client", %{conn: conn} do
      nhs()
      contract_request = insert(:il, :contract_request)

      id = Node.to_global_id("ContractRequest", contract_request.id)

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contractRequest))

      assert nil == resp_body["errors"]
      assert id == resp_entity["id"]
    end

    test "success for correct MSP client", %{conn: conn} do
      msp()

      contract_request = insert(:il, :contract_request)

      id = Node.to_global_id("ContractRequest", contract_request.id)

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id(contract_request.contractor_legal_entity_id)
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contractRequest))

      assert nil == resp_body["errors"]
      assert id == resp_entity["id"]
    end

    test "return nothing for incorrect MSP client", %{conn: conn} do
      msp()

      contract_request = insert(:il, :contract_request)

      id = Node.to_global_id("ContractRequest", contract_request.id)

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contractRequest))

      assert nil == resp_body["errors"]
      assert nil == resp_entity
    end

    test "return forbidden error for incorrect client type", %{conn: conn} do
      mis()

      contract_request = insert(:il, :contract_request)

      id = Node.to_global_id("ContractRequest", contract_request.id)

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contractRequest))

      assert is_list(resp_body["errors"])
      assert match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, hd(resp_body["errors"]))
      assert nil == resp_entity
    end

    test "success with related entities", %{conn: conn} do
      nhs()

      previous_request = insert(:il, :contract_request)
      assignee = insert(:prm, :employee)
      contractor_legal_entity = insert(:prm, :legal_entity)
      contractor_owner = insert(:prm, :employee)
      contractor_division = insert(:prm, :division)
      contractor_employee = insert(:prm, :employee)
      external_contractor_legal_entity = insert(:prm, :legal_entity)
      external_contractor_division = insert(:prm, :division)
      nhs_signer = insert(:prm, :employee)

      contract_request =
        insert(:il, :contract_request, %{
          previous_request: previous_request,
          assignee_id: assignee.id,
          contractor_legal_entity_id: contractor_legal_entity.id,
          contractor_owner_id: contractor_owner.id,
          contractor_divisions: [contractor_division.id],
          contractor_employee_divisions: [
            %{
              "employee_id" => contractor_employee.id,
              "division_id" => contractor_division.id
            }
          ],
          external_contractors: [
            %{
              "legal_entity_id" => external_contractor_legal_entity.id,
              "divisions" => [%{"id" => external_contractor_division.id}]
            }
          ],
          nhs_signer_id: nhs_signer.id
        })

      id = Node.to_global_id("ContractRequest", contract_request.id)

      query = """
        query GetContractRequestWithRelatedEntitiesQuery($id: ID!) {
          contractRequest(id: $id) {
            # parentContract {
            #   id
            # }
            previousRequest {
              databaseId
            }
            assignee {
              databaseId
            }
            contractorLegalEntity {
              databaseId
            }
            contractorOwner {
              databaseId
            }
            contractorDivisions {
              databaseId
            }
            contractorEmployeeDivisions {
              employee {
                databaseId
              }
              division {
                databaseId
              }
            }
            externalContractors {
              legalEntity {
                databaseId
              }
              divisions {
                division {
                  databaseId
                }
              }
            }
            nhsSigner {
              databaseId
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

      resp_entity = get_in(resp_body, ~w(data contractRequest))

      assert nil == resp_body["errors"]
      assert previous_request.id == resp_entity["previousRequest"]["databaseId"]
      assert assignee.id == resp_entity["assignee"]["databaseId"]
      assert contractor_legal_entity.id == resp_entity["contractorLegalEntity"]["databaseId"]
      assert contractor_owner.id == resp_entity["contractorOwner"]["databaseId"]
      assert contractor_division.id == hd(resp_entity["contractorDivisions"])["databaseId"]
      assert contractor_employee.id == hd(resp_entity["contractorEmployeeDivisions"])["employee"]["databaseId"]
      assert contractor_division.id == hd(resp_entity["contractorEmployeeDivisions"])["division"]["databaseId"]
      assert external_contractor_legal_entity.id == hd(resp_entity["externalContractors"])["legalEntity"]["databaseId"]

      assert external_contractor_division.id ==
               resp_entity["externalContractors"]
               |> hd()
               |> get_in(~w(divisions))
               |> hd()
               |> get_in(~w(division databaseId))

      assert nhs_signer.id == resp_entity["nhsSigner"]["databaseId"]
    end
  end
end
