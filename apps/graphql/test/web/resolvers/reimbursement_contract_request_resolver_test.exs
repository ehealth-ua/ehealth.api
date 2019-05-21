defmodule GraphQL.ReimbursementContractRequestResolverTest do
  @moduledoc false

  use GraphQL.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3, insert_list: 3, build: 2]
  import Core.Expectations.Man, only: [template: 1]
  import Core.Expectations.Mithril, only: [nhs: 0]
  import Core.Expectations.Signature
  import Mox, only: [expect: 3, expect: 4, verify_on_exit!: 1]

  alias Absinthe.Relay.Node
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.Contracts.CapitationContract
  alias Ecto.UUID

  @list_query """
    query ListContractRequestsQuery(
      $filter: ReimbursementContractRequestFilter
      $orderBy: ReimbursementContractRequestOrderBy
    ) {
      reimbursementContractRequests(first: 10, filter: $filter, orderBy: $orderBy) {
        nodes {
          id
          databaseId
        }
      }
    }
  """

  @approve_query """
    mutation ApproveContractRequestMutation($input: ApproveContractRequestInput!) {
      approveContractRequest(input: $input) {
        contractRequest {
          id
          databaseId
          status

          ... on ReimbursementContractRequest {
            medicalProgram {
              databaseId
              name
            }
          }
        }
      }
    }
  """

  @update_query """
    mutation UpdateContractRequestMutation($input: UpdateContractRequestInput!) {
      updateContractRequest(input: $input) {
        contractRequest {
          miscellaneous
          nhsSignerBase
          nhsPaymentMethod
        }
      }
    }
  """

  @assign_query """
    mutation AssignContractRequestMutation($input: AssignContractRequestInput) {
      assignContractRequest(input: $input) {
        contractRequest {
          id
          status
          assignee {
            id
          }
        }
      }
    }
  """

  @decline_query """
    mutation DeclineContractRequestMutation($input: DeclineContractRequestInput!) {
      declineContractRequest(input: $input) {
        contractRequest {
          id
          databaseId
          status

          ... on ReimbursementContractRequest {
            medicalProgram {
              databaseId
            }
          }
        }
      }
    }
  """

  @sign_query """
    mutation SignContractRequest($input: SignContractRequestInput!) {
      signContractRequest(input: $input) {
        contractRequest {
          id
          databaseId
          status
          printoutContent
        }
      }
    }
  """

  @contract_request_status_new ReimbursementContractRequest.status(:new)
  @contract_request_status_in_process ReimbursementContractRequest.status(:in_process)
  @contract_request_status_pending_nhs_sign ReimbursementContractRequest.status(:pending_nhs_sign)
  @contract_request_status_nhs_signed ReimbursementContractRequest.status(:nhs_signed)

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn = put_scope(conn, "contract_request:read contract_request:update")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "query all", %{conn: conn} do
      nhs()

      insert_list(2, :il, :reimbursement_contract_request)
      insert_list(10, :il, :capitation_contract_request)

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, %{filter: %{}})
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data reimbursementContractRequests nodes))

      refute resp_body["errors"]
      assert 2 == length(resp_entities)
    end
  end

  describe "get by id" do
    test "success with attached documents", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://example.com/#{id}/#{resource_name}"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, 2, fn _url -> {:ok, %{status_code: 200, body: ""}} end)

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

      attached_documents = get_in(resp_body, ~w(data reimbursementContractRequest attachedDocuments))

      refute resp_body["errors"]
      assert 2 == length(attached_documents)

      Enum.each(attached_documents, fn document ->
        assert Map.has_key?(document, "type")
        assert Map.has_key?(document, "url")
      end)
    end

    test "success without attached documents", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://example.com/#{id}/#{resource_name}"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, 2, fn url ->
        {:ok,
         %{
           status_code: 200,
           body:
             "<?xml version='1.0' encoding='UTF-8'?><Error><Code>NoSuchKey</Code><Message>" <>
               "The specified key does not exist.</Message><Details>No such object: #{url}</Details></Error>"
         }}
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

      refute resp_body["errors"]
      assert [] == get_in(resp_body, ~w(data reimbursementContractRequest attachedDocuments))
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

      refute resp_body["errors"]

      addresses = get_in(resp_body, ~w(data reimbursementContractRequest contractorLegalEntity addresses))
      assert [%{"building" => nil}, %{"building" => ""}] == addresses
    end
  end

  describe "update" do
    setup %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      nhs_signer = insert(:prm, :employee, legal_entity: legal_entity)
      nhs_signer_id = Node.to_global_id("Employee", nhs_signer.id)

      {:ok, conn: conn, nhs_signer_id: nhs_signer_id, legal_entity: legal_entity}
    end

    test "success", %{conn: conn, nhs_signer_id: nhs_signer_id, legal_entity: legal_entity} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: @contract_request_status_in_process,
          start_date: Date.add(Date.utc_today(), 10)
        )

      id = Node.to_global_id("ReimbursementContractRequest", contract_request.id)

      variables = %{
        input: %{
          id: id,
          nhs_signer_id: nhs_signer_id,
          nhs_signer_base: "на підставі наказу",
          nhs_payment_method: "BACKWARD",
          miscellaneous: "Всяке дозволене"
        }
      }

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> post_query(@update_query, variables)
        |> json_response(200)

      refute resp_body["errors"]

      resp_entity = get_in(resp_body, ~w(data updateContractRequest contractRequest))

      assert variables.input.miscellaneous == resp_entity["miscellaneous"]
      assert variables.input.nhs_signer_base == resp_entity["nhsSignerBase"]
      assert variables.input.nhs_payment_method == resp_entity["nhsPaymentMethod"]
    end

    test "nhs_contract_price is not allowed", %{conn: conn, nhs_signer_id: nhs_signer_id, legal_entity: legal_entity} do
      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: @contract_request_status_in_process,
          start_date: Date.add(Date.utc_today(), 10)
        )

      id = Node.to_global_id("ReimbursementContractRequest", contract_request.id)

      variables = %{
        input: %{
          id: id,
          nhsSignerId: nhs_signer_id,
          nhsSignerBase: "на підставі наказу",
          nhsContractPrice: 150_000,
          nhsPaymentMethod: "BACKWARD",
          miscellaneous: "Всяке дозволене"
        }
      }

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> post_query(@update_query, variables)
        |> json_response(200)

      refute get_in(resp_body, ~w(data updateContractRequest))

      assert [
               %{
                 "path" => ["updateContractRequest"],
                 "extensions" => %{
                   "code" => "UNPROCESSABLE_ENTITY",
                   "exception" => %{
                     "inputErrors" => [
                       %{
                         "message" => "schema does not allow additional properties",
                         "path" => ["nhsContractPrice"]
                       }
                     ]
                   }
                 }
               }
             ] = resp_body["errors"]
    end

    test "cannot update reimbursement contract request when global id for capitation", %{
      conn: conn,
      nhs_signer_id: nhs_signer_id,
      legal_entity: legal_entity
    } do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: @contract_request_status_in_process,
          start_date: Date.add(Date.utc_today(), 10)
        )

      id = Node.to_global_id("CapitationContractRequest", contract_request.id)

      variables = %{
        input: %{
          id: id,
          nhs_signer_id: nhs_signer_id,
          nhs_contract_price: 100
        }
      }

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> post_query(@update_query, variables)
        |> json_response(200)

      assert Enum.any?(resp_body["errors"], &match?(%{"extensions" => %{"code" => "NOT_FOUND"}}, &1))
    end
  end

  describe "update assignee" do
    test "success", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MithrilMock, :search_user_roles, fn _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)

      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user)
      employee = insert(:prm, :employee, legal_entity: legal_entity, party: party_user.party)
      contract_request = insert(:il, :reimbursement_contract_request, status: @contract_request_status_new)

      id = Node.to_global_id("ReimbursementContractRequest", contract_request.id)
      employee_id = Node.to_global_id("Employee", employee.id)

      variables = %{input: %{id: id, employeeId: employee_id}}

      resp_body =
        conn
        |> put_consumer_id()
        |> put_client_id(legal_entity.id)
        |> post_query(@assign_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data assignContractRequest contractRequest))

      refute resp_body["errors"]
      assert id == resp_entity["id"]
      assert @contract_request_status_in_process == resp_entity["status"]
      assert employee_id == resp_entity["assignee"]["id"]
    end

    test "wrong contract request type", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user)
      employee = insert(:prm, :employee, legal_entity: legal_entity, party: party_user.party)
      contract_request = insert(:il, :reimbursement_contract_request, status: @contract_request_status_new)

      id = Node.to_global_id("CapitationContractRequest", contract_request.id)
      employee_id = Node.to_global_id("Employee", employee.id)

      variables = %{input: %{id: id, employeeId: employee_id}}

      resp_body =
        conn
        |> put_consumer_id()
        |> put_client_id(legal_entity.id)
        |> post_query(@assign_query, variables)
        |> json_response(200)

      refute get_in(resp_body, ~w(data assignContractRequest))

      assert match?(
               %{"message" => "Contract Request not found", "extensions" => %{"code" => "NOT_FOUND"}},
               hd(resp_body["errors"])
             )
    end
  end

  describe "approve" do
    setup %{conn: conn} do
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity, nhs_verified: true)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:pharmacy_owner),
          party: party_user.party
        )

      division =
        insert(
          :prm,
          :division,
          type: Division.type(:drugstore),
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
        )

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      medical_program = insert(:prm, :medical_program)

      {:ok,
       conn: conn,
       division: division,
       legal_entity: legal_entity,
       employee_owner: employee_owner,
       start_date: start_date,
       party_user: party_user,
       medical_program: medical_program}
    end

    test "success", context do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)

      %{
        conn: conn,
        division: division,
        party_user: party_user,
        start_date: start_date,
        legal_entity: legal_entity,
        employee_owner: employee_owner,
        medical_program: medical_program
      } = context

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: ReimbursementContractRequest.status(:in_process),
          nhs_signer_id: employee_owner.id,
          nhs_legal_entity_id: legal_entity.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          start_date: start_date,
          medical_program_id: medical_program.id
        )

      content = %{
        "id" => contract_request.id,
        "next_status" => "APPROVED",
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      expect_signed_content(content, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> put_consumer_id(party_user.user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> put_scope("contract_request:update")
        |> post_query(@approve_query, input_signed_content(contract_request.id, content))
        |> json_response(200)

      refute resp_body["errors"]
      resp_contract_request = get_in(resp_body, ~w(data approveContractRequest contractRequest))

      assert medical_program.id == resp_contract_request["medicalProgram"]["databaseId"]
    end

    test "invalid parent contract status", context do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      %{
        conn: conn,
        division: division,
        party_user: party_user,
        start_date: start_date,
        legal_entity: legal_entity,
        employee_owner: employee_owner,
        medical_program: medical_program
      } = context

      parent_contract = insert(:prm, :reimbursement_contract, status: CapitationContract.status(:terminated))

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: ReimbursementContractRequest.status(:in_process),
          nhs_signer_id: employee_owner.id,
          nhs_legal_entity_id: legal_entity.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          start_date: start_date,
          medical_program_id: medical_program.id,
          parent_contract_id: parent_contract.id
        )

      content = %{
        "id" => contract_request.id,
        "next_status" => "APPROVED",
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      expect_signed_content(content, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> put_consumer_id(party_user.user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> put_scope("contract_request:update")
        |> post_query(@approve_query, input_signed_content(contract_request.id, content))
        |> json_response(200)

      assert Enum.any?(resp_body["errors"], &match?(%{"extensions" => %{"code" => "CONFLICT"}}, &1))
      assert [error] = resp_body["errors"]
      assert "Parent contract can’t be updated" == error["message"]
    end
  end

  describe "sign" do
    test "success", %{conn: conn} do
      template(1)
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})
      insert(:il, :dictionary, name: "POSITION", values: %{})
      nhs()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)

      %{
        user_id: user_id,
        division: division,
        legal_entity: legal_entity,
        nhs_signer_id: nhs_signer_id,
        employee_owner: employee_owner,
        medical_program: medical_program,
        nhs_signer_party: nhs_signer_party
      } = prepare_data()

      id = UUID.generate()
      now = Date.utc_today()

      data = %{
        "id" => id,
        "contract_number" => "0000-9EAX-XT7X-3115",
        "status" => @contract_request_status_pending_nhs_sign
      }

      insert(
        :il,
        :reimbursement_contract_request,
        id: id,
        data: data,
        status: @contract_request_status_pending_nhs_sign,
        nhs_signed_date: Date.add(now, -10),
        nhs_legal_entity_id: legal_entity.id,
        nhs_signer_id: nhs_signer_id,
        contractor_legal_entity_id: legal_entity.id,
        contractor_owner_id: employee_owner.id,
        contractor_divisions: [division.id],
        medical_program_id: medical_program.id,
        start_date: Date.add(now, 10)
      )

      printout_content = "<html></html>"
      content = Map.put(data, "printout_content", printout_content)

      expect_signed_content(content, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer_party.tax_id,
          surname: nhs_signer_party.last_name
        },
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer_party.tax_id,
          surname: nhs_signer_party.last_name,
          is_stamp: true
        }
      ])

      resp_body =
        conn
        |> put_scope("contract_request:sign")
        |> put_consumer_id(user_id)
        |> put_client_id(legal_entity.id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post_query(@sign_query, input_signed_content(id, content))
        |> json_response(200)

      refute resp_body["errors"]

      resp_entity = get_in(resp_body, ~w(data signContractRequest contractRequest))

      assert %{"status" => @contract_request_status_nhs_signed, "printoutContent" => ^printout_content} = resp_entity
    end

    test "medical program not exist", %{conn: conn} do
      template(1)
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})
      insert(:il, :dictionary, name: "POSITION", values: %{})
      nhs()

      %{
        user_id: user_id,
        division: division,
        legal_entity: legal_entity,
        nhs_signer_id: nhs_signer_id,
        employee_owner: employee_owner,
        nhs_signer_party: nhs_signer_party
      } = prepare_data()

      id = UUID.generate()
      now = Date.utc_today()

      data = %{
        "id" => id,
        "contract_number" => "0000-9EAX-XT7X-3115",
        "status" => @contract_request_status_pending_nhs_sign
      }

      insert(
        :il,
        :reimbursement_contract_request,
        id: id,
        data: data,
        status: @contract_request_status_pending_nhs_sign,
        nhs_signed_date: Date.add(now, -10),
        nhs_legal_entity_id: legal_entity.id,
        nhs_signer_id: nhs_signer_id,
        contractor_legal_entity_id: legal_entity.id,
        contractor_owner_id: employee_owner.id,
        contractor_divisions: [division.id],
        medical_program_id: UUID.generate(),
        start_date: Date.add(now, 10)
      )

      printout_content = "<html></html>"
      content = Map.put(data, "printout_content", printout_content)

      expect_signed_content(content, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer_party.tax_id,
          surname: nhs_signer_party.last_name
        },
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer_party.tax_id,
          surname: nhs_signer_party.last_name,
          is_stamp: true
        }
      ])

      resp_body =
        conn
        |> put_scope("contract_request:sign")
        |> put_consumer_id(user_id)
        |> put_client_id(legal_entity.id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post_query(@sign_query, input_signed_content(id, content))
        |> json_response(200)

      refute get_in(resp_body, ~w(data signContractRequest))

      assert [
               %{
                 "path" => ["signContractRequest"],
                 "extensions" => %{
                   "code" => "UNPROCESSABLE_ENTITY",
                   "exception" => %{
                     "inputErrors" => [
                       %{
                         "message" => "Reimbursement program with such id does not exist",
                         "options" => %{"rule" => "invalid"},
                         "path" => ["medicalProgramId"]
                       }
                     ]
                   }
                 }
               }
             ] = resp_body["errors"]
    end

    test "medical program not active", %{conn: conn} do
      template(1)
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})
      insert(:il, :dictionary, name: "POSITION", values: %{})
      nhs()

      %{
        user_id: user_id,
        division: division,
        legal_entity: legal_entity,
        nhs_signer_id: nhs_signer_id,
        employee_owner: employee_owner,
        nhs_signer_party: nhs_signer_party
      } = prepare_data()

      medical_program = insert(:prm, :medical_program, is_active: false)

      id = UUID.generate()
      now = Date.utc_today()

      data = %{
        "id" => id,
        "contract_number" => "0000-9EAX-XT7X-3115",
        "status" => @contract_request_status_pending_nhs_sign
      }

      insert(
        :il,
        :reimbursement_contract_request,
        id: id,
        data: data,
        status: @contract_request_status_pending_nhs_sign,
        nhs_signed_date: Date.add(now, -10),
        nhs_legal_entity_id: legal_entity.id,
        nhs_signer_id: nhs_signer_id,
        contractor_legal_entity_id: legal_entity.id,
        contractor_owner_id: employee_owner.id,
        contractor_divisions: [division.id],
        medical_program_id: medical_program.id,
        start_date: Date.add(now, 10)
      )

      printout_content = "<html></html>"
      content = Map.put(data, "printout_content", printout_content)

      expect_signed_content(content, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer_party.tax_id,
          surname: nhs_signer_party.last_name
        },
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer_party.tax_id,
          surname: nhs_signer_party.last_name,
          is_stamp: true
        }
      ])

      resp_body =
        conn
        |> put_scope("contract_request:sign")
        |> put_consumer_id(user_id)
        |> put_client_id(legal_entity.id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post_query(@sign_query, input_signed_content(id, content))
        |> json_response(200)

      assert match?(
               %{"message" => "Reimbursement program is not active", "extensions" => %{"code" => "CONFLICT"}},
               hd(resp_body["errors"])
             )
    end
  end

  describe "decline contract_request" do
    test "success decline contract request", %{conn: conn} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)

      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:pharmacy_owner),
          party: party_user.party
        )

      insert(:prm, :division, type: Division.type(:drugstore), legal_entity: legal_entity)

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: ReimbursementContractRequest.status(:in_process),
          nhs_signer_id: employee_owner.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id
        )

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      data = %{
        "id" => contract_request.id,
        "next_status" => "DECLINED",
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "status_reason" => "Не відповідає попереднім домовленостям",
        "text" => "something"
      }

      expect_signed_content(data, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> put_consumer_id(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> put_scope("contract_request:update")
        |> post_query(@decline_query, input_signed_content(contract_request.id, data))
        |> json_response(200)

      refute resp_body["errors"]
      resp_contract_request = get_in(resp_body, ~w(data declineContractRequest contractRequest))

      assert ReimbursementContractRequest.status(:declined) == resp_contract_request["status"]

      contract_request = Core.Repo.get(ReimbursementContractRequest, contract_request.id)
      assert contract_request.status_reason == "Не відповідає попереднім домовленостям"
      assert contract_request.nhs_signer_id == user_id
      assert contract_request.nhs_legal_entity_id == legal_entity.id
    end
  end

  defp input_signed_content(contract_request_id, content) do
    %{
      input: %{
        id: Node.to_global_id("ReimbursementContractRequest", contract_request_id),
        signedContent: %{
          content: content |> Jason.encode!() |> Base.encode64(),
          encoding: "BASE64"
        }
      }
    }
  end

  defp prepare_data do
    user_id = UUID.generate()
    nhs_signer_id = UUID.generate()

    legal_entity = insert(:prm, :legal_entity, nhs_verified: true)
    %{party: nhs_signer_party} = build(:party_user, user_id: nhs_signer_id)

    insert(
      :prm,
      :employee,
      legal_entity_id: legal_entity.id,
      id: nhs_signer_id,
      party: nhs_signer_party
    )

    division =
      insert(
        :prm,
        :division,
        type: Division.type(:drugstore),
        legal_entity: legal_entity,
        phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
      )

    employee_owner =
      insert(
        :prm,
        :employee,
        id: user_id,
        legal_entity_id: legal_entity.id,
        employee_type: Employee.type(:pharmacy_owner)
      )

    medical_program = insert(:prm, :medical_program)

    %{
      user_id: user_id,
      division: division,
      legal_entity: legal_entity,
      nhs_signer_id: nhs_signer_id,
      employee_owner: employee_owner,
      medical_program: medical_program,
      nhs_signer_party: nhs_signer_party
    }
  end
end
