defmodule GraphQLWeb.ContractResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3, build: 2]
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

  @get_by_id_query """
    query GetContractQuery($id: ID!) {
      contract(id: $id) {
        id
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

    test "order by contractor legal_entity edrpou", %{conn: conn} do
      nhs()

      contract3 = insert(:prm, :contract, contractor_legal_entity: build(:legal_entity, edrpou: "77744433322"))
      contract1 = insert(:prm, :contract, contractor_legal_entity: build(:legal_entity, edrpou: "33344433322"))
      contract2 = insert(:prm, :contract, contractor_legal_entity: build(:legal_entity, edrpou: "55544433322"))

      query = """
        query ListContractsQuery($orderBy: ContractOrderBy) {
          contracts(first: 10, orderBy: $orderBy) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{orderBy: "CONTRACTOR_LEGAL_ENTITY_EDRPOU_ASC"}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contracts nodes))

      refute resp_body["errors"]
      assert 3 == length(resp_entities)
      assert [contract1.id, contract2.id, contract3.id] == Enum.map(resp_entities, & &1["databaseId"])
    end
  end

  describe "get by id" do
    setup %{conn: conn} do
      contract = insert(:prm, :contract)
      global_contract_id = Node.to_global_id("Contract", contract.id)
      {:ok, conn: conn, contract: contract, global_contract_id: global_contract_id}
    end

    test "success for NHS client", %{conn: conn, global_contract_id: global_contract_id} do
      nhs()

      variables = %{id: global_contract_id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contract))

      refute resp_body["errors"]
      assert global_contract_id == resp_entity["id"]
    end

    test "success for correct MSP client", %{conn: conn, contract: contract, global_contract_id: global_contract_id} do
      msp()

      variables = %{id: global_contract_id}

      resp_body =
        conn
        |> put_client_id(contract.contractor_legal_entity_id)
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contract))

      refute resp_body["errors"]
      assert global_contract_id == resp_entity["id"]
    end

    test "return nothing for incorrect MSP client", %{conn: conn} = context do
      msp()

      variables = %{id: context.global_contract_id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contract))

      refute resp_body["errors"]
      refute resp_entity
    end

    test "return forbidden error for incorrect client type", %{conn: conn} = context do
      mis()

      variables = %{id: context.global_contract_id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contract))

      assert is_list(resp_body["errors"])
      assert match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, hd(resp_body["errors"]))
      refute resp_entity
    end

    test "success with related entities", %{conn: conn} do
      nhs()

      parent_contract = insert(:prm, :contract)
      contractor_legal_entity = insert(:prm, :legal_entity)
      contractor_owner = insert(:prm, :employee)
      contractor_employee = insert(:prm, :employee)
      external_contractor_legal_entity = insert(:prm, :legal_entity)
      external_contractor_division = insert(:prm, :division)
      nhs_signer = insert(:prm, :employee)
      nhs_legal_entity = insert(:prm, :legal_entity)

      contractor_division = insert(:prm, :division, name: "Будьте здорові!")
      contractor_employee_division = insert(:prm, :division, name: "Та Ви не хворійте!")

      contract_request = insert(:il, :contract_request)

      contract =
        insert(
          :prm,
          :contract,
          parent_contract: parent_contract,
          contractor_legal_entity: contractor_legal_entity,
          contractor_owner: contractor_owner,
          external_contractors: [
            %{
              "legal_entity_id" => external_contractor_legal_entity.id,
              "divisions" => [%{"id" => external_contractor_division.id}]
            }
          ],
          nhs_signer: nhs_signer,
          nhs_legal_entity: nhs_legal_entity,
          contract_request_id: contract_request.id
        )

      insert(
        :prm,
        :contract_employee,
        contract_id: contract.id,
        employee_id: contractor_employee.id,
        division_id: contractor_division.id
      )

      insert(
        :prm,
        :contract_employee,
        contract_id: contract.id,
        employee_id: contractor_employee.id,
        division_id: contractor_employee_division.id
      )

      insert(:prm, :contract_division, contract_id: contract.id, division_id: contractor_division.id)
      insert(:prm, :contract_division, contract_id: contract.id, division_id: contractor_employee_division.id)

      id = Node.to_global_id("Contract", contract.id)

      query = """
        query GetContractWithRelatedEntitiesQuery(
            $id: ID!,
            $divisionFilter: DivisionFilter!,
            $contractorEmployeeDivisionFilter: ContractorEmployeeDivisionFilter)
          {
          contract(id: $id) {
            contractorLegalEntity {
              databaseId
            }
            contractorOwner {
              databaseId
            }
            contractorDivisions(first: 1, filter: $divisionFilter) {
              nodes{
                databaseId
                name
              }
            }
            contractorEmployeeDivisions(first: 1, filter: $contractorEmployeeDivisionFilter) {
              nodes{
                databaseId
                employee {
                  databaseId
                }
                division {
                  databaseId
                  name
                }
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
            nhsLegalEntity {
              databaseId
            }
            parentContract {
              databaseId
            }
            contractRequest {
              databaseId
            }
            insertedAt
            updatedAt
          }
        }
      """

      variables = %{
        id: id,
        divisionFilter: %{
          databaseId: contractor_division.id,
          name: "здоров"
        },
        contractorEmployeeDivisionFilter: %{
          division: %{
            databaseId: contractor_employee_division.id,
            name: "хвор"
          }
        }
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contract))

      refute resp_body["errors"]

      assert resp_entity["insertedAt"]
      assert resp_entity["updatedAt"]

      assert parent_contract.id == resp_entity["parentContract"]["databaseId"]
      assert contract_request.id == resp_entity["contractRequest"]["databaseId"]

      assert contractor_legal_entity.id == resp_entity["contractorLegalEntity"]["databaseId"]
      assert contractor_owner.id == resp_entity["contractorOwner"]["databaseId"]
      assert contractor_division.id == hd(resp_entity["contractorDivisions"]["nodes"])["databaseId"]
      assert contractor_division.name == hd(resp_entity["contractorDivisions"]["nodes"])["name"]
      assert contractor_employee.id == hd(resp_entity["contractorEmployeeDivisions"]["nodes"])["employee"]["databaseId"]

      assert contractor_employee_division.id ==
               hd(resp_entity["contractorEmployeeDivisions"]["nodes"])["division"]["databaseId"]

      assert contractor_employee_division.name ==
               hd(resp_entity["contractorEmployeeDivisions"]["nodes"])["division"]["name"]

      assert external_contractor_legal_entity.id == hd(resp_entity["externalContractors"])["legalEntity"]["databaseId"]

      assert external_contractor_division.id ==
               resp_entity["externalContractors"]
               |> hd()
               |> get_in(~w(divisions))
               |> hd()
               |> get_in(~w(division databaseId))

      assert nhs_signer.id == resp_entity["nhsSigner"]["databaseId"]
      assert nhs_legal_entity.id == resp_entity["nhsLegalEntity"]["databaseId"]
    end

    test "success with attached documents", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 3, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://example.com/#{id}/#{resource_name}"}}}
      end)

      contract_request = insert(:il, :contract_request, status: ContractRequest.status(:signed))
      contract = insert(:prm, :contract, contract_request_id: contract_request.id)

      id = Node.to_global_id("Contract", contract.id)

      query = """
        query GetContractWithAttachedDocumentsQuery($id: ID!) {
          contract(id: $id) {
            contractRequest{
              databaseId
            }
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

      attached_documents = get_in(resp_body, ~w(data contract attachedDocuments))

      refute resp_body["errors"]
      assert 3 == length(attached_documents)

      Enum.each(attached_documents, fn document ->
        assert Map.has_key?(document, "type")
        assert Map.has_key?(document, "url")
      end)
    end

    test "Media Storage invalid response for attachedDocuments", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 1, fn _, _, _id, _resource_name, _ ->
        {:error, %{"error" => %{"message" => "not found"}}}
      end)

      contract_request = insert(:il, :contract_request)
      contract = insert(:prm, :contract, contract_request_id: contract_request.id)

      id = Node.to_global_id("Contract", contract.id)

      query = """
        query GetContractWithAttachedDocumentsQuery($id: ID!) {
          contract(id: $id) {
            attachedDocuments {
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

      assert resp_body["errors"]
      refute get_in(resp_body, ~w(data contract attachedDocuments))
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

  describe "prolongate contract" do
    test "success", %{conn: conn} do
      nhs()

      legal_entity = insert(:prm, :legal_entity)
      contractor_legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, is_active: true, merged_from: contractor_legal_entity)

      contract =
        insert(:prm, :contract, nhs_legal_entity: legal_entity, contractor_legal_entity: contractor_legal_entity)

      end_date = Date.utc_today() |> Date.add(23) |> to_string()

      variables = %{
        input: %{
          id: Node.to_global_id("Contract", contract.id),
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
