defmodule GraphQLWeb.CapitationContractResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3, insert_list: 3, build: 2]
  import Core.Expectations.Mithril
  import Core.Expectations.Signature, only: [edrpou_signed_content: 2]
  import Mox

  alias Absinthe.Relay.Node
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Utils.TypesConverter
  alias Ecto.UUID

  @list_query """
    query ListContractsQuery($filter: CapitationContractFilter) {
      capitationContracts(first: 10, filter: $filter) {
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
      capitationContract(id: $id) {
        id
      }
    }
  """

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn = put_scope(conn, "contract:terminate contract:read")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "return all for NHS client", %{conn: conn} do
      nhs()

      insert_list(2, :prm, :capitation_contract)
      insert_list(10, :prm, :reimbursement_contract)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)
    end

    test "return only related for MSP client", %{conn: conn} do
      msp()

      contract = for _ <- 1..2, do: insert(:prm, :capitation_contract)
      related_contract = hd(contract)

      resp_body =
        conn
        |> put_client_id(related_contract.contractor_legal_entity_id)
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert related_contract.id == hd(resp_entities)["databaseId"]
    end

    test "return forbidden error for incorrect client type", %{conn: conn} do
      mis()

      for _ <- 1..2, do: insert(:prm, :capitation_contract)

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

      for status <- ~w(VERIFIED TERMINATED), do: insert(:prm, :capitation_contract, %{status: status})

      variables = %{filter: %{status: "VERIFIED"}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert "VERIFIED" == hd(resp_entities)["status"]
    end

    test "filter by closed date interval", %{conn: conn} do
      nhs()

      today = Date.utc_today()

      for start_date <- [today, Date.add(today, -30)], do: insert(:prm, :capitation_contract, %{start_date: start_date})

      variables = %{
        filter: %{startDate: to_string(%Date.Interval{first: today, last: Date.add(today, 10)})}
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert to_string(today) == hd(resp_entities)["startDate"]
    end

    test "filter by open date interval", %{conn: conn} do
      nhs()

      today = Date.utc_today()

      for start_date <- [today, Date.add(today, -30)], do: insert(:prm, :capitation_contract, %{start_date: start_date})

      variables = %{
        filter: %{startDate: Date.Interval.to_edtf(%{first: today, last: nil})}
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert to_string(today) == hd(resp_entities)["startDate"]
    end

    test "filter by legal entity relation", %{conn: conn} do
      nhs(2)
      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_from: from, merged_to: to, is_active: false)
      insert(:prm, :related_legal_entity, merged_from: from, merged_to: to)
      contract_related_from = insert(:prm, :capitation_contract, %{contractor_legal_entity: from})
      contract_related_to = insert(:prm, :capitation_contract, %{contractor_legal_entity: to})

      # merged from
      variables = %{
        filter: %{
          legalEntityRelation: "MERGED_FROM",
          isSuspended: false,
          status: contract_related_from.status
        }
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

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

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      refute resp_body["errors"]
      assert 1 == length(resp_entities)
      assert contract_related_to.id == hd(resp_entities)["databaseId"]
    end

    test "order by contractor legal_entity edrpou", %{conn: conn} do
      nhs()

      contract3 =
        insert(:prm, :capitation_contract, contractor_legal_entity: build(:legal_entity, edrpou: "77744433322"))

      contract1 =
        insert(:prm, :capitation_contract, contractor_legal_entity: build(:legal_entity, edrpou: "33344433322"))

      contract2 =
        insert(:prm, :capitation_contract, contractor_legal_entity: build(:legal_entity, edrpou: "55544433322"))

      query = """
        query ListContractsQuery($orderBy: CapitationContractOrderBy) {
          capitationContracts(first: 10, orderBy: $orderBy) {
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

      resp_entities = get_in(resp_body, ~w(data capitationContracts nodes))

      refute resp_body["errors"]
      assert 3 == length(resp_entities)
      assert [contract1.id, contract2.id, contract3.id] == Enum.map(resp_entities, & &1["databaseId"])
    end
  end

  describe "get by id" do
    setup %{conn: conn} do
      contract = insert(:prm, :capitation_contract)
      global_contract_id = Node.to_global_id("CapitationContract", contract.id)
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

      resp_entity = get_in(resp_body, ~w(data capitationContract))

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

      resp_entity = get_in(resp_body, ~w(data capitationContract))

      refute resp_body["errors"]
      assert global_contract_id == resp_entity["id"]
    end

    test "error on media storage fetch printoutContent field", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, fn _ ->
        {:error, {:conflict, "Failed to get signed_content"}}
      end)

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          status: CapitationContractRequest.status(:pending_nhs_sign)
        )

      contract = insert(:prm, :capitation_contract, contract_request_id: contract_request.id)

      query = """
        query GetContractQuery($id: ID!) {
          capitationContract(id: $id) {
            id
            databaseId
            status
            printoutContent
          }
        }
      """

      variables = %{id: Node.to_global_id("CapitationContract", contract.id)}

      resp_body =
        conn
        |> put_client_id(contract.contractor_legal_entity_id)
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data capitationContract))

      refute resp_entity["printoutContent"]
      assert resp_entity["status"]
    end

    test "success for printoutContent field", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 1, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, 1, fn _ ->
        {:ok, %{body: "", status_code: 200}}
      end)

      query = """
        query GetContractQuery($id: ID!) {
          capitationContract(id: $id) {
            id
            printoutContent
          }
        }
      """

      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})

      client_id = UUID.generate()
      nhs_signer = insert(:prm, :employee)
      external_contractor_legal_entity = insert(:prm, :legal_entity)
      external_contractor_division = insert(:prm, :division)
      printout_content = "<html></html>"

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          nhs_signer_id: nhs_signer.id,
          contractor_legal_entity_id: client_id,
          status: CapitationContractRequest.status(:pending_nhs_sign),
          printout_content: printout_content,
          external_contractors: [
            %{
              "legal_entity_id" => external_contractor_legal_entity.id,
              "divisions" => [
                %{
                  "id" => external_contractor_division.id,
                  "medical_service" => "Послуга ПМД"
                }
              ]
            }
          ]
        )

      legal_entity_signer = insert(:prm, :legal_entity, edrpou: "10002000")
      edrpou_signed_content(TypesConverter.atoms_to_strings(contract_request), legal_entity_signer.edrpou)

      contract = insert(:prm, :capitation_contract, contract_request_id: contract_request.id)
      variables = %{id: Node.to_global_id("CapitationContract", contract.id)}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data capitationContract))

      refute resp_body["errors"]
      assert printout_content == resp_entity["printoutContent"]
    end

    test "return nothing for incorrect MSP client", %{conn: conn} = context do
      msp()

      variables = %{id: context.global_contract_id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data capitationContract))

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

      resp_entity = get_in(resp_body, ~w(data capitationContract))

      assert is_list(resp_body["errors"])
      assert match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, hd(resp_body["errors"]))
      refute resp_entity
    end

    test "success with related entities", %{conn: conn} do
      nhs()

      parent_contract = insert(:prm, :capitation_contract)
      contractor_legal_entity = insert(:prm, :legal_entity)
      contractor_owner = insert(:prm, :employee)
      contractor_employee = insert(:prm, :employee)
      external_contractor_legal_entity = insert(:prm, :legal_entity)
      external_contractor_division = insert(:prm, :division)
      nhs_signer = insert(:prm, :employee)
      nhs_legal_entity = insert(:prm, :legal_entity)

      contractor_division = insert(:prm, :division, name: "Будьте здорові!")
      contractor_employee_division = insert(:prm, :division, name: "Та Ви не хворійте!")

      contract_request = insert(:il, :capitation_contract_request)

      contract =
        insert(
          :prm,
          :capitation_contract,
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

      id = Node.to_global_id("CapitationContract", contract.id)

      query = """
        query GetContractWithRelatedEntitiesQuery(
            $id: ID!,
            $divisionFilter: DivisionFilter!,
            $contractorEmployeeDivisionFilter: ContractorEmployeeDivisionFilter)
          {
          capitationContract(id: $id) {
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

      resp_entity = get_in(resp_body, ~w(data capitationContract))

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

      contract_request = insert(:il, :capitation_contract_request, status: CapitationContractRequest.status(:signed))
      contract = insert(:prm, :capitation_contract, contract_request_id: contract_request.id)

      id = Node.to_global_id("CapitationContract", contract.id)

      query = """
        query GetContractWithAttachedDocumentsQuery($id: ID!) {
          capitationContract(id: $id) {
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

      attached_documents = get_in(resp_body, ~w(data capitationContract attachedDocuments))

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

      contract_request = insert(:il, :capitation_contract_request)
      contract = insert(:prm, :capitation_contract, contract_request_id: contract_request.id)

      id = Node.to_global_id("CapitationContract", contract.id)

      query = """
        query GetContractWithAttachedDocumentsQuery($id: ID!) {
          capitationContract(id: $id) {
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
      refute get_in(resp_body, ~w(data capitationContract attachedDocuments))
    end
  end
end
