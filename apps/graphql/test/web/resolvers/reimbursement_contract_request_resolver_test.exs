defmodule GraphQLWeb.ReimbursementContractRequestResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3, insert_list: 3]
  import Core.Expectations.Mithril, only: [nhs: 0]
  import Core.Expectations.Signature
  import Mox, only: [expect: 3, expect: 4, verify_on_exit!: 1]

  alias Absinthe.Relay.Node
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Employees.Employee
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

  @contract_request_status_new ReimbursementContractRequest.status(:new)
  @contract_request_status_in_process ReimbursementContractRequest.status(:in_process)

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
          nhs_signer_id: nhs_signer_id,
          nhs_signer_base: "на підставі наказу",
          nhs_contract_price: 150_000,
          nhs_payment_method: "BACKWARD",
          miscellaneous: "Всяке дозволене"
        }
      }

      errors =
        conn
        |> put_client_id(legal_entity.id)
        |> post_query(@update_query, variables)
        |> json_response(200)
        |> Map.get("errors")

      assert Enum.any?(errors, &match?(%{"extensions" => %{"code" => "UNPROCESSABLE_ENTITY"}}, &1))

      assert [error] = errors
      assert "schema does not allow additional properties" == hd(error["errors"])["$.nhs_contract_price"]["description"]
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
      legal_entity = insert(:prm, :legal_entity)

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
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
        )

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      medical_program = insert(:prm, :medical_program)

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

      {:ok,
       conn: conn,
       contract_request: contract_request,
       legal_entity: legal_entity,
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

      %{
        conn: conn,
        contract_request: contract_request,
        legal_entity: legal_entity,
        party_user: party_user,
        medical_program: medical_program
      } = context

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
  end

  describe "decline contract_request" do
    test "success decline contract request", %{conn: conn} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

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

      insert(:prm, :division, legal_entity: legal_entity)

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
end
