defmodule GraphQLWeb.CapidationContractRequestResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3, build: 2]
  import Core.Expectations.Man, only: [template: 0]
  import Core.Expectations.Mithril, only: [msp: 0, nhs: 0]
  import Core.Expectations.Signature
  import Mox, only: [expect: 3, expect: 4, verify_on_exit!: 1]

  alias Absinthe.Relay.Node
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Employees.Employee
  alias Core.EventManagerRepo
  alias Core.EventManager.Event
  alias Core.Repo
  alias Ecto.UUID

  @contract_request_status_new CapitationContractRequest.status(:new)
  @contract_request_status_in_process CapitationContractRequest.status(:in_process)
  @contract_request_status_pending_nhs_sign CapitationContractRequest.status(:pending_nhs_sign)
  @contract_request_status_nhs_signed CapitationContractRequest.status(:nhs_signed)

  @printout_content_query """
    query GetContractRequestPrintoutContentQuery($id: ID!) {
      capitationContractRequest(id: $id) {
        status
        printoutContent
        toSignContent
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

          ... on CapitationContractRequest {
            nhsContractPrice
          }
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

          ... on CapitationContractRequest {
            contractorEmployeeDivisions {
              employee {
                databaseId
              }
              division {
                databaseId
              }
            }
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

          ... on CapitationContractRequest {
            contractorEmployeeDivisions {
              employee {
                databaseId
              }
              division {
                databaseId
              }
            }
          }
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

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn = put_scope(conn, "contract_request:read contract_request:update")

    {:ok, %{conn: conn}}
  end

  describe "get by id" do
    test "success with related entities", %{conn: conn} do
      nhs()

      parent_contract = insert(:prm, :capitation_contract)
      previous_request = insert(:il, :capitation_contract_request)
      assignee = insert(:prm, :employee)
      contractor_legal_entity = insert(:prm, :legal_entity)
      contractor_owner = insert(:prm, :employee)
      contractor_division = insert(:prm, :division)
      contractor_employee = insert(:prm, :employee)
      external_contractor_legal_entity = insert(:prm, :legal_entity)
      external_contractor_division = insert(:prm, :division)
      nhs_signer = insert(:prm, :employee)
      nhs_legal_entity = insert(:prm, :legal_entity)

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          parent_contract_id: parent_contract.id,
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
          nhs_signer_id: nhs_signer.id,
          nhs_legal_entity_id: nhs_legal_entity.id
        )

      id = Node.to_global_id("CapitationContractRequest", contract_request.id)

      query = """
        query GetContractRequestWithRelatedEntitiesQuery($id: ID!) {
          capitationContractRequest(id: $id) {
            parentContract {
              databaseId
            }
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
            nhsLegalEntity {
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

      resp_entity = get_in(resp_body, ~w(data capitationContractRequest))

      assert nil == resp_body["errors"]
      assert parent_contract.id == resp_entity["parentContract"]["databaseId"]
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
      assert nhs_legal_entity.id == resp_entity["nhsLegalEntity"]["databaseId"]
    end

    test "success with attached documents", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://example.com/#{id}/#{resource_name}"}}}
      end)

      contract_request = insert(:il, :capitation_contract_request)

      id = Node.to_global_id("CapitationContractRequest", contract_request.id)

      query = """
        query GetContractRequestWithAttachedDocumentsQuery($id: ID!) {
          capitationContractRequest(id: $id) {
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

      resp_entities = get_in(resp_body, ~w(data capitationContractRequest attachedDocuments))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)

      Enum.each(resp_entities, fn document ->
        assert Map.has_key?(document, "type")
        assert Map.has_key?(document, "url")
      end)
    end

    test "success with review content to sign", %{conn: conn} do
      nhs()

      approved_text = "Yay! I'm approved!"
      declined_text = "Sadly, but I'm declined."

      insert(
        :il,
        :dictionary,
        name: "CONTRACT_REQUEST_REVIEW_TEXT",
        values: %{"APPROVED" => approved_text, "DECLINED" => declined_text}
      )

      contract_request = insert(:il, :capitation_contract_request, status: @contract_request_status_in_process)

      %{id: database_id} = contract_request
      id = Node.to_global_id("CapitationContractRequest", database_id)

      query = """
        query GetContractRequestWithContentToSignQuery($id: ID!) {
          capitationContractRequest(id: $id) {
            toApproveContent
            toDeclineContent
          }
        }
      """

      variables = %{id: id}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data capitationContractRequest))

      assert nil == resp_body["errors"]

      assert match?(
               %{
                 "id" => ^database_id,
                 "contractor_legal_entity" => %{"edrpou" => _, "id" => _, "name" => _},
                 "next_status" => "APPROVED",
                 "text" => ^approved_text
               },
               resp_entity["toApproveContent"]
             )

      assert match?(
               %{
                 "id" => ^database_id,
                 "contractor_legal_entity" => %{"edrpou" => _, "id" => _, "name" => _},
                 "next_status" => "DECLINED",
                 "text" => ^declined_text
               },
               resp_entity["toDeclineContent"]
             )
    end
  end

  describe "get with printout_content field" do
    test "success with pending status", %{conn: conn} do
      nhs()
      template()
      template()

      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})

      client_id = UUID.generate()
      nhs_signer = insert(:prm, :employee)
      external_contractor_legal_entity = insert(:prm, :legal_entity)
      external_contractor_division = insert(:prm, :division)

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          nhs_signer_id: nhs_signer.id,
          contractor_legal_entity_id: client_id,
          status: @contract_request_status_pending_nhs_sign,
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

      variables = %{id: Node.to_global_id("CapitationContractRequest", contract_request.id)}

      resp_body =
        conn
        |> put_client_id(client_id)
        |> post_query(@printout_content_query, variables)
        |> json_response(200)

      assert "<html></html>" == get_in(resp_body, ~w(data capitationContractRequest printoutContent))
      assert get_in(resp_body, ~w(data capitationContractRequest toSignContent))
    end

    test "success with contract_request another status", %{conn: conn} do
      nhs()

      printout_content = "<html></html>"

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          status: CapitationContractRequest.status(:new),
          printout_content: printout_content
        )

      variables = %{id: Node.to_global_id("CapitationContractRequest", contract_request.id)}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@printout_content_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data capitationContractRequest))

      assert %{"printoutContent" => ^printout_content} = resp_entity
    end

    test "User is not allowed to perform this action", %{conn: conn} do
      msp()
      contract_request = insert(:il, :capitation_contract_request, status: @contract_request_status_pending_nhs_sign)
      variables = %{id: Node.to_global_id("CapitationContractRequest", contract_request.id)}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@printout_content_query, variables)
        |> json_response(200)

      assert %{"data" => %{"capitationContractRequest" => nil}} = resp_body
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
          :capitation_contract_request,
          status: @contract_request_status_in_process,
          start_date: Date.add(Date.utc_today(), 10)
        )

      id = Node.to_global_id("CapitationContractRequest", contract_request.id)

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

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> post_query(@update_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data updateContractRequest contractRequest))

      assert variables.input.miscellaneous == resp_entity["miscellaneous"]
      assert variables.input.nhs_signer_base == resp_entity["nhsSignerBase"]
      assert variables.input.nhs_contract_price == resp_entity["nhsContractPrice"]
      assert variables.input.nhs_payment_method == resp_entity["nhsPaymentMethod"]
    end

    test "invalid nhs contract price", %{conn: conn, nhs_signer_id: nhs_signer_id, legal_entity: legal_entity} do
      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          status: @contract_request_status_in_process,
          start_date: Date.add(Date.utc_today(), 10)
        )

      id = Node.to_global_id("CapitationContractRequest", contract_request.id)

      variables = %{
        input: %{
          id: id,
          nhs_signer_id: nhs_signer_id,
          nhs_contract_price: -1
        }
      }

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> post_query(@update_query, variables)
        |> json_response(200)

      assert Enum.any?(resp_body["errors"], &match?(%{"extensions" => %{"code" => "UNPROCESSABLE_ENTITY"}}, &1))

      assert [error] = resp_body["errors"]
      assert "expected the value to be >= 0" == hd(error["errors"])["$.nhs_contract_price"]["description"]
    end

    test "Start date must be greater than create date", %{
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
          :capitation_contract_request,
          status: @contract_request_status_in_process,
          start_date: ~D[2000-01-01]
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

      assert Enum.any?(resp_body["errors"], &match?(%{"extensions" => %{"code" => "UNPROCESSABLE_ENTITY"}}, &1))

      assert [error] = resp_body["errors"]
      assert "Start date must be within this or next year" == hd(error["errors"])["$.start_date"]["description"]
    end

    test "contract request not found", %{conn: conn, nhs_signer_id: nhs_signer_id, legal_entity: legal_entity} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      id = Node.to_global_id("CapitationContractRequest", UUID.generate())

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
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
        )

      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          status: CapitationContractRequest.status(:in_process),
          nhs_signer_id: employee_owner.id,
          nhs_legal_entity_id: legal_entity.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ],
          start_date: start_date
        )

      {:ok,
       conn: conn,
       contract_request: contract_request,
       legal_entity: legal_entity,
       division: division,
       party_user: party_user,
       employee_doctor: employee_doctor}
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
        division: division,
        employee_doctor: employee_doctor,
        party_user: party_user
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
      contractor_employee_divisions = hd(resp_contract_request["contractorEmployeeDivisions"])
      assert employee_doctor.id == contractor_employee_divisions["employee"]["databaseId"]
      assert division.id == contractor_employee_divisions["division"]["databaseId"]
    end

    test "invalid response from DS", context do
      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:error,
         %{
           "meta" => %{
             "url" => "http://api-svc.digital-signature.svc.cluster.local/digital_signatures",
             "type" => "object",
             "request_id" => "b006b174-42ff-4199-9a2e-88381e34392e#77823",
             "code" => 422
           },
           "error" => %{
             "type" => "validation_failed",
             "message" => "Validation failed. You can find validators ...",
             "invalid" => [
               %{
                 "rules" => [
                   %{
                     "rule" => "invalid",
                     "params" => [],
                     "description" => "Not a base64 string"
                   }
                 ],
                 "entry_type" => "json_data_property",
                 "entry" => "$.signed_content"
               }
             ]
           }
         }}
      end)

      %{
        conn: conn,
        contract_request: contract_request,
        legal_entity: legal_entity,
        party_user: party_user
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

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> put_consumer_id(party_user.user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> put_scope("contract_request:update")
        |> post_query(@approve_query, input_signed_content(contract_request.id, content))
        |> json_response(200)

      refute resp_body["data"]["approveContractRequest"]

      assert match?(
               %{"message" => "Validation error", "extensions" => %{"code" => "UNPROCESSABLE_ENTITY"}},
               hd(resp_body["errors"])
             )
    end

    test "invalid HTTP error", context do
      import ExUnit.CaptureLog

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:error, {:errconn, "Bad Gateway"}}
      end)

      %{
        conn: conn,
        contract_request: contract_request,
        legal_entity: legal_entity,
        party_user: party_user
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

      assert capture_log(fn ->
               resp_body =
                 conn
                 |> put_client_id(legal_entity.id)
                 |> put_consumer_id(party_user.user_id)
                 |> put_req_header("drfo", legal_entity.edrpou)
                 |> put_scope("contract_request:update")
                 |> post_query(@approve_query, input_signed_content(contract_request.id, content))
                 |> json_response(200)

               refute resp_body["data"]["approveContractRequest"]

               assert match?(
                        %{"message" => "Undefined error", "extensions" => %{"code" => "BAD_REQUEST"}},
                        hd(resp_body["errors"])
                      )
             end) =~ "Got undefined error"
    end
  end

  describe "decline" do
    test "success", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, "success"} end)

      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division = insert(:prm, :division, legal_entity: legal_entity)

      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      contract_request =
        insert(
          :il,
          :capitation_contract_request,
          status: @contract_request_status_in_process,
          nhs_signer_id: employee_owner.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ]
        )

      content = %{
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

      expect_signed_content(content, %{
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
        |> post_query(@decline_query, input_signed_content(contract_request.id, content))
        |> json_response(200)

      refute resp_body["errors"]
      resp_contract_request = get_in(resp_body, ~w(data declineContractRequest contractRequest))

      assert CapitationContractRequest.status(:declined) == resp_contract_request["status"]
      contractor_employee_divisions = hd(resp_contract_request["contractorEmployeeDivisions"])
      assert employee_doctor.id == contractor_employee_divisions["employee"]["databaseId"]
      assert division.id == contractor_employee_divisions["division"]["databaseId"]

      contract_request = Repo.get(CapitationContractRequest, contract_request.id)
      assert contract_request.status_reason == "Не відповідає попереднім домовленостям"
      assert contract_request.nhs_signer_id == user_id
      assert contract_request.nhs_legal_entity_id == legal_entity.id

      contract_request_id = contract_request.id
      contract_request_status = contract_request.status
      assert event = EventManagerRepo.one(Event)

      assert %Event{
               entity_type: "CapitationContractRequest",
               event_type: "StatusChangeEvent",
               entity_id: ^contract_request_id,
               changed_by: ^user_id,
               properties: %{"status" => %{"new_value" => ^contract_request_status}}
             } = event
    end
  end

  describe "sign" do
    test "success", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})
      nhs()
      template()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      id = UUID.generate()
      user_id = UUID.generate()
      nhs_signer_id = UUID.generate()
      now = Date.utc_today()

      %{id: client_id} = legal_entity = insert(:prm, :legal_entity)
      %{party: nhs_signer_party} = build(:party_user, user_id: nhs_signer_id)

      insert(
        :prm,
        :employee,
        legal_entity_id: client_id,
        id: nhs_signer_id,
        party: nhs_signer_party
      )

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
        )

      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      employee_owner =
        insert(
          :prm,
          :employee,
          id: user_id,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner)
        )

      data = %{
        "id" => id,
        "contract_number" => "0000-9EAX-XT7X-3115",
        "status" => @contract_request_status_pending_nhs_sign
      }

      insert(
        :il,
        :capitation_contract_request,
        id: id,
        data: data,
        status: @contract_request_status_pending_nhs_sign,
        nhs_signed_date: Date.add(now, -10),
        nhs_legal_entity_id: client_id,
        nhs_signer_id: nhs_signer_id,
        contractor_legal_entity_id: client_id,
        contractor_owner_id: employee_owner.id,
        contractor_divisions: [division.id],
        contractor_employee_divisions: [
          %{
            "employee_id" => employee_doctor.id,
            "staff_units" => 0.5,
            "declaration_limit" => 2000,
            "division_id" => division.id
          }
        ],
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
        |> put_client_id(client_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post_query(@sign_query, input_signed_content(id, content))
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data signContractRequest contractRequest))

      assert nil == resp_body["errors"]
      assert %{"status" => @contract_request_status_nhs_signed, "printoutContent" => ^printout_content} = resp_entity
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
      contract_request = insert(:il, :capitation_contract_request, status: @contract_request_status_new)

      id = Node.to_global_id("CapitationContractRequest", contract_request.id)
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

    test "invalid employee status", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user)
      employee = insert(:prm, :employee, legal_entity: legal_entity, party: party_user.party, status: "DISMISSED")
      contract_request = insert(:il, :capitation_contract_request, status: @contract_request_status_new)

      id = Node.to_global_id("CapitationContractRequest", contract_request.id)
      employee_id = Node.to_global_id("Employee", employee.id)

      variables = %{input: %{id: id, employeeId: employee_id}}

      resp_body =
        conn
        |> put_consumer_id()
        |> put_client_id(legal_entity.id)
        |> post_query(@assign_query, variables)
        |> json_response(200)

      refute resp_body["data"]["assignContractRequest"]

      assert match?(
               %{"message" => "Invalid employee status", "extensions" => %{"code" => "CONFLICT"}},
               hd(resp_body["errors"])
             )
    end
  end

  defp input_signed_content(contract_request_id, content) do
    %{
      input: %{
        id: Node.to_global_id("CapitationContractRequest", contract_request_id),
        signedContent: %{
          content: content |> Jason.encode!() |> Base.encode64(),
          encoding: "BASE64"
        }
      }
    }
  end
end
