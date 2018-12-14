defmodule GraphQLWeb.ReimbursementContractResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3, insert_list: 3, build: 2]
  import Core.Expectations.Mithril
  import Mox

  alias Absinthe.Relay.Node
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Ecto.UUID

  @list_query """
    query ListContractsQuery($filter: ReimbursementContractFilter) {
      reimbursementContracts(first: 10, filter: $filter) {
        nodes {
          id
          databaseId
          status
          startDate
          nhsSigner {
            databaseId
          }
          medicalProgram {
            name
          }
        }
      }
    }
  """

  @get_by_id_query """
    query GetContractQuery($id: ID!) {
      reimbursementContract(id: $id) {
        id
      }
    }
  """

  @printout_content_query """
    query GetContractQuery($id: ID!) {
      reimbursementContract(id: $id) {
        id
        printoutContent
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

      insert_list(2, :prm, :reimbursement_contract)
      insert_list(10, :prm, :capitation_contract)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)
    end

    test "return only related for PHARMACY client", %{conn: conn} do
      pharmacy()

      contract = for _ <- 1..2, do: insert(:prm, :reimbursement_contract)
      related_contract = hd(contract)

      resp_body =
        conn
        |> put_client_id(related_contract.contractor_legal_entity_id)
        |> post_query(@list_query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert related_contract.id == hd(resp_entities)["databaseId"]
    end

    test "return forbidden error for incorrect client type", %{conn: conn} do
      mis()

      for _ <- 1..2, do: insert(:prm, :reimbursement_contract)

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

      for status <- ~w(VERIFIED TERMINATED), do: insert(:prm, :reimbursement_contract, %{status: status})

      variables = %{filter: %{status: "VERIFIED"}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert "VERIFIED" == hd(resp_entities)["status"]
    end

    test "filter by closed date interval", %{conn: conn} do
      nhs()

      today = Date.utc_today()

      for start_date <- [today, Date.add(today, -30)],
          do: insert(:prm, :reimbursement_contract, %{start_date: start_date})

      variables = %{
        filter: %{startDate: to_string(%Date.Interval{first: today, last: Date.add(today, 10)})}
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert to_string(today) == hd(resp_entities)["startDate"]
    end

    test "filter by open date interval", %{conn: conn} do
      nhs()

      today = Date.utc_today()

      for start_date <- [today, Date.add(today, -30)],
          do: insert(:prm, :reimbursement_contract, %{start_date: start_date})

      variables = %{
        filter: %{startDate: Date.Interval.to_edtf(%{first: today, last: nil})}
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert to_string(today) == hd(resp_entities)["startDate"]
    end

    test "filter by legal entity relation", %{conn: conn} do
      nhs(2)
      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_from: from, merged_to: to)
      contract_related_from = insert(:prm, :reimbursement_contract, %{contractor_legal_entity: from})
      contract_related_to = insert(:prm, :reimbursement_contract, %{contractor_legal_entity: to})

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

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

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

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      refute resp_body["errors"]
      assert 1 == length(resp_entities)
      assert contract_related_to.id == hd(resp_entities)["databaseId"]
    end

    test "order by contractor legal_entity edrpou", %{conn: conn} do
      nhs()

      contract3 =
        insert(:prm, :reimbursement_contract, contractor_legal_entity: build(:legal_entity, edrpou: "77744433322"))

      contract1 =
        insert(:prm, :reimbursement_contract, contractor_legal_entity: build(:legal_entity, edrpou: "33344433322"))

      contract2 =
        insert(:prm, :reimbursement_contract, contractor_legal_entity: build(:legal_entity, edrpou: "55544433322"))

      query = """
        query ListContractsQuery($orderBy: ReimbursementContractOrderBy) {
          reimbursementContracts(first: 10, orderBy: $orderBy) {
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

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      refute resp_body["errors"]
      assert 3 == length(resp_entities)
      assert [contract1.id, contract2.id, contract3.id] == Enum.map(resp_entities, & &1["databaseId"])
    end

    test "order by medical_program name", %{conn: conn} do
      nhs()

      insert_contract =
        &insert(:prm, :reimbursement_contract, medical_program_id: insert(:prm, :medical_program, name: &1).id)

      medical_programs_name = ["Unknown program 3", "Available medications 1", "Free medications 2"]

      [contract3, contract1, contract2] = Enum.map(medical_programs_name, &insert_contract.(&1))

      query = """
        query ListContractsQuery($orderBy: ReimbursementContractOrderBy) {
          reimbursementContracts(first: 10, orderBy: $orderBy) {
            nodes {
              databaseId
              medicalProgram {
                name
              }
            }
          }
        }
      """

      variables = %{orderBy: "MEDICAL_PROGRAM_NAME_ASC"}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      assert [contract1.id, contract2.id, contract3.id] == Enum.map(resp_entities, & &1["databaseId"])
    end

    test "filter by medical_program attributes", %{conn: conn} do
      nhs()

      insert_medical_program = &insert(:prm, :medical_program, is_active: &1, name: &2).id
      insert_contract = &insert(:prm, :reimbursement_contract, medical_program_id: insert_medical_program.(&1, &2))

      insert_contract.(true, "Medical program")
      insert_contract.(true, "Available program")
      insert_contract.(true, "Available medications")
      insert_contract.(false, "Free medications program")
      insert_contract.(false, "Unknown drugs")

      query = """
        query ListContractsQuery($filter: ReimbursementContractFilter) {
          reimbursementContracts(first: 10, filter: $filter) {
            nodes {
              databaseId
              medicalProgram {
                name
                isActive
              }
            }
          }
        }
      """

      variables = %{filter: %{medicalProgram: %{isActive: true, name: "program"}}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      [entity, _] = resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))

      refute resp_body["errors"]
      assert 2 == length(resp_entities)
      assert true == entity["medicalProgram"]["isActive"]
      assert String.contains?(entity["medicalProgram"]["name"], "program")
    end

    test "filter by contractor_legal_entity attributes", %{conn: conn} do
      nhs()

      insert_contract = &insert(:prm, :reimbursement_contract, contractor_legal_entity: build(:legal_entity, &1))

      %{id: contract_id} = insert_contract.(nhs_verified: true)
      %{id: contract_id2} = insert_contract.(edrpou: "111", nhs_verified: true)
      insert_contract.(edrpou: "222", nhs_verified: false)

      query = """
        query ListContractsQuery($filter: ReimbursementContractFilter!) {
          reimbursementContracts(first: 10, filter: $filter) {
            nodes {
              databaseId

              contractorLegalEntity {
                databaseId
                nhsVerified
              }
            }
          }
        }
      """

      variables = %{filter: %{contractorLegalEntity: %{nhsVerified: true}}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContracts nodes))
      resp_entities_ids = get_in(resp_entities, [Access.all(), "databaseId"])

      refute resp_body["errors"]
      assert 2 == length(resp_entities)
      assert true == hd(resp_entities)["contractorLegalEntity"]["nhsVerified"]
      assert MapSet.new([contract_id, contract_id2]) == MapSet.new(resp_entities_ids)
    end
  end

  describe "get by id" do
    setup %{conn: conn} do
      contract = insert(:prm, :reimbursement_contract)
      global_contract_id = Node.to_global_id("ReimbursementContract", contract.id)
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

      resp_entity = get_in(resp_body, ~w(data reimbursementContract))

      refute resp_body["errors"]
      assert global_contract_id == resp_entity["id"]
    end

    test "success for correct PHARMACY client",
         %{conn: conn, contract: contract, global_contract_id: global_contract_id} do
      pharmacy()

      variables = %{id: global_contract_id}

      resp_body =
        conn
        |> put_client_id(contract.contractor_legal_entity_id)
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContract))

      refute resp_body["errors"]
      assert global_contract_id == resp_entity["id"]
    end

    test "return nothing for incorrect PHARMACY client", %{conn: conn} = context do
      pharmacy()

      variables = %{id: context.global_contract_id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@get_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContract))

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

      resp_entity = get_in(resp_body, ~w(data reimbursementContract))

      assert is_list(resp_body["errors"])
      assert match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, hd(resp_body["errors"]))
      refute resp_entity
    end

    test "success for printoutContent field", %{conn: conn} do
      nhs()

      printout_content = "<html>Some printout content is here</html>"
      contract_request = insert(:il, :reimbursement_contract_request, printout_content: printout_content)
      contract = insert(:prm, :reimbursement_contract, contract_request_id: contract_request.id)
      variables = %{id: Node.to_global_id("ReimbursementContract", contract.id)}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@printout_content_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContract))

      refute resp_body["errors"]
      assert printout_content == resp_entity["printoutContent"]
    end

    test "fails on reimbursementContract not found resolving printoutContent", %{conn: conn} do
      nhs()

      contract = insert(:prm, :reimbursement_contract, contract_request_id: UUID.generate())
      variables = %{id: Node.to_global_id("ReimbursementContract", contract.id)}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@printout_content_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContract))

      assert resp_entity
      refute resp_entity["printoutContent"]
      assert %{"errors" => [error]} = resp_body
      assert "NOT_FOUND" == error["extensions"]["code"]
    end

    test "success with related entities", %{conn: conn} do
      nhs()

      parent_contract = insert(:prm, :reimbursement_contract)
      contractor_legal_entity = insert(:prm, :legal_entity)
      contractor_owner = insert(:prm, :employee)
      contractor_employee = insert(:prm, :employee)
      nhs_signer = insert(:prm, :employee)
      nhs_legal_entity = insert(:prm, :legal_entity)

      contractor_division = insert(:prm, :division, name: "Будьте здорові!")
      contractor_employee_division = insert(:prm, :division, name: "Та Ви не хворійте!")

      contract_request = insert(:il, :reimbursement_contract_request)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      contract =
        insert(
          :prm,
          :reimbursement_contract,
          parent_contract: parent_contract,
          contractor_legal_entity: contractor_legal_entity,
          contractor_owner: contractor_owner,
          nhs_signer: nhs_signer,
          nhs_legal_entity: nhs_legal_entity,
          contract_request_id: contract_request.id,
          medical_program_id: medical_program_id
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

      id = Node.to_global_id("ReimbursementContract", contract.id)

      query = """
        query GetContractWithRelatedEntitiesQuery(
            $id: ID!,
            $divisionFilter: DivisionFilter!)
          {
          reimbursementContract(id: $id) {
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
            contractRequest {
              databaseId
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
            medicalProgram {
              name
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
        }
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data reimbursementContract))

      refute resp_body["errors"]

      assert resp_entity["insertedAt"]
      assert resp_entity["updatedAt"]

      assert parent_contract.id == resp_entity["parentContract"]["databaseId"]
      assert contract_request.id == resp_entity["contractRequest"]["databaseId"]

      assert medical_program_id == resp_entity["medicalProgram"]["databaseId"]

      assert contractor_legal_entity.id == resp_entity["contractorLegalEntity"]["databaseId"]
      assert contractor_owner.id == resp_entity["contractorOwner"]["databaseId"]
      assert contractor_division.id == hd(resp_entity["contractorDivisions"]["nodes"])["databaseId"]
      assert contractor_division.name == hd(resp_entity["contractorDivisions"]["nodes"])["name"]

      assert nhs_signer.id == resp_entity["nhsSigner"]["databaseId"]
      assert nhs_legal_entity.id == resp_entity["nhsLegalEntity"]["databaseId"]
    end

    test "success with attached documents", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 3, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://example.com/#{id}/#{resource_name}"}}}
      end)

      contract_request =
        insert(:il, :reimbursement_contract_request, status: ReimbursementContractRequest.status(:signed))

      contract = insert(:prm, :reimbursement_contract, contract_request_id: contract_request.id)

      id = Node.to_global_id("ReimbursementContract", contract.id)

      query = """
        query GetContractWithAttachedDocumentsQuery($id: ID!) {
          reimbursementContract(id: $id) {
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

      attached_documents = get_in(resp_body, ~w(data reimbursementContract attachedDocuments))

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

      contract_request = insert(:il, :reimbursement_contract_request)
      contract = insert(:prm, :reimbursement_contract, contract_request_id: contract_request.id)

      id = Node.to_global_id("ReimbursementContract", contract.id)

      query = """
        query GetContractWithAttachedDocumentsQuery($id: ID!) {
          reimbursementContract(id: $id) {
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
      refute get_in(resp_body, ~w(data reimbursementContract attachedDocuments))
    end
  end
end
