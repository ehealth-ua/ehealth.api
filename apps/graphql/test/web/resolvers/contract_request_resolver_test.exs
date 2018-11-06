defmodule GraphQLWeb.ContractRequestResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories, only: [insert: 2, insert: 3, build: 2]
  import Core.Expectations.Man, only: [template: 0]
  import Core.Expectations.Mithril, only: [mis: 0, msp: 0, nhs: 0]
  import Core.Expectations.Signature
  import Mox, only: [expect: 3, expect: 4, verify_on_exit!: 1]

  alias Absinthe.Relay.Node
  alias Core.ContractRequests.ContractRequest
  alias Core.Employees.Employee
  alias Core.EventManagerRepo
  alias Core.EventManager.Event
  alias Core.Repo
  alias Ecto.UUID

  @contract_request_status_new ContractRequest.status(:new)
  @contract_request_status_in_process ContractRequest.status(:in_process)
  @contract_request_status_pending_nhs_sign ContractRequest.status(:pending_nhs_sign)
  @contract_request_status_nhs_signed ContractRequest.status(:nhs_signed)

  @list_query """
    query ListContractRequestsQuery($filter: ContractRequestFilter, $orderBy: ContractRequestOrderBy) {
      contractRequests(first: 10, filter: $filter, orderBy: $orderBy) {
        nodes {
          id
          databaseId
          status
          startDate
          contractorLegalEntity {
            databaseId
          }
          assignee {
            databaseId
          }
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

  @printout_content_query """
    query GetContractRequestPrintoutContentQuery($id: ID!) {
      contractRequest(id: $id) {
        status
        printoutContent
      }
    }
  """

  @update_query """
    mutation UpdateContractRequestMutation($input: UpdateContractRequestInput!) {
      updateContractRequest(input: $input) {
        contractRequest {
          miscellaneous
          nhsSignerBase
          nhsContractPrice
          nhsPaymentMethod
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
  """

  @decline_query """
    mutation DeclineContractRequestMutation($input: DeclineContractRequestInput!) {
      declineContractRequest(input: $input) {
        contractRequest {
          id
          databaseId
          status
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

      for status <- ~w(NEW APPROWED), do: insert(:il, :contract_request, status: status)

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

    test "filter by database ID", %{conn: conn} do
      nhs()

      contract_requests = for _ <- 1..2, do: insert(:il, :contract_request)

      requested_contract_request = hd(contract_requests)

      variables = %{filter: %{databaseId: requested_contract_request.id}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert [resp_entity] = resp_entities
      assert requested_contract_request.id == resp_entity["databaseId"]
    end

    test "filter by closed date interval", %{conn: conn} do
      nhs()

      today = Date.utc_today()

      for start_date <- [today, Date.add(today, -30)], do: insert(:il, :contract_request, start_date: start_date)

      variables = %{
        filter: %{startDate: to_string(%Date.Interval{first: today, last: Date.add(today, 10)})}
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert to_string(today) == hd(resp_entities)["startDate"]
    end

    test "filter by open date interval", %{conn: conn} do
      nhs()

      today = Date.utc_today()

      for start_date <- [today, Date.add(today, -30)], do: insert(:il, :contract_request, start_date: start_date)

      variables = %{
        filter: %{startDate: to_string(%Date.Interval{first: today, last: nil})}
      }

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert to_string(today) == hd(resp_entities)["startDate"]
    end

    test "filter by contractor legal entity edrpou", %{conn: conn} do
      nhs()

      contractor_legal_entities =
        for edrpou <- ["1234567890", "0987654321"] do
          insert(:prm, :legal_entity, edrpou: edrpou)
        end

      for %{id: id} <- contractor_legal_entities, do: insert(:il, :contract_request, contractor_legal_entity_id: id)

      requested_contractor_legal_entity = hd(contractor_legal_entities)

      variables = %{filter: %{contractorLegalEntityEdrpou: requested_contractor_legal_entity.edrpou}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert requested_contractor_legal_entity.id == hd(resp_entities)["contractorLegalEntity"]["databaseId"]
    end

    test "filter by assignee name", %{conn: conn} do
      nhs()

      assignees = for _ <- 1..2, do: insert(:prm, :employee, %{employee_type: "NHS"})
      for %{id: id} <- assignees, do: insert(:il, :contract_request, %{assignee_id: id})

      requested_assignee = hd(assignees)

      variables = %{filter: %{assigneeName: requested_assignee.party.last_name}}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert 1 == length(resp_entities)
      assert requested_assignee.id == hd(resp_entities)["assignee"]["databaseId"]
    end

    test "success with ordering", %{conn: conn} do
      nhs()

      for status <- [@contract_request_status_in_process, @contract_request_status_new] do
        insert(:il, :contract_request, status: status)
      end

      variables = %{orderBy: "STATUS_ASC"}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data contractRequests nodes))

      assert nil == resp_body["errors"]
      assert @contract_request_status_in_process == hd(resp_entities)["status"]
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
        insert(
          :il,
          :contract_request,
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
        )

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

    test "success with attached documents", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://example.com/#{id}/#{resource_name}"}}}
      end)

      contract_request = insert(:il, :contract_request)

      id = Node.to_global_id("ContractRequest", contract_request.id)

      query = """
        query GetContractRequestWithAttachedDocumentsQuery($id: ID!) {
          contractRequest(id: $id) {
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

      resp_entities = get_in(resp_body, ~w(data contractRequest attachedDocuments))

      assert nil == resp_body["errors"]
      assert 2 == length(resp_entities)

      Enum.each(resp_entities, fn document ->
        assert Map.has_key?(document, "type")
        assert Map.has_key?(document, "url")
      end)
    end
  end

  describe "get with printout_content field" do
    test "success with pending status", %{conn: conn} do
      nhs()
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
          :contract_request,
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

      variables = %{id: Node.to_global_id("ContractRequest", contract_request.id)}

      resp_body =
        conn
        |> put_client_id(client_id)
        |> post_query(@printout_content_query, variables)
        |> json_response(200)

      assert "<html></html>" == get_in(resp_body, ~w(data contractRequest printoutContent))
    end

    test "success with contract_request another status", %{conn: conn} do
      nhs()

      printout_content = "<html></html>"

      contract_request =
        insert(:il, :contract_request, status: ContractRequest.status(:new), printout_content: printout_content)

      variables = %{id: Node.to_global_id("ContractRequest", contract_request.id)}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@printout_content_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data contractRequest))

      assert %{"printoutContent" => ^printout_content} = resp_entity
    end

    test "User is not allowed to perform this action", %{conn: conn} do
      msp()
      contract_request = insert(:il, :contract_request, status: @contract_request_status_pending_nhs_sign)
      variables = %{id: Node.to_global_id("ContractRequest", contract_request.id)}

      resp_body =
        conn
        |> put_client_id()
        |> post_query(@printout_content_query, variables)
        |> json_response(200)

      assert %{"data" => %{"contractRequest" => nil}} = resp_body
    end
  end

  describe "update" do
    test "success", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      nhs_signer = insert(:prm, :employee, legal_entity: legal_entity)

      contract_request =
        insert(
          :il,
          :contract_request,
          status: @contract_request_status_in_process,
          start_date: Date.add(Date.utc_today(), 10)
        )

      id = Node.to_global_id("ContractRequest", contract_request.id)
      nhs_signer_id = Node.to_global_id("Employee", nhs_signer.id)

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
  end

  describe "approve" do
    test "success", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

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
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}],
          working_hours: %{fri: [["08.00", "12.00"], ["14.00", "16.00"]]}
        )

      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      contract_request =
        insert(
          :il,
          :contract_request,
          status: ContractRequest.status(:in_process),
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

      drfo_signed_content(content, legal_entity.edrpou, party_user.party.last_name)

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> put_consumer_id(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> put_scope("contract_request:update")
        |> post_query(@approve_query, input_signed_content(content))
        |> json_response(200)

      resp_contract_request = get_in(resp_body, ~w(data approveContractRequest contractRequest))
      contractor_employee_divisions = hd(resp_contract_request["contractorEmployeeDivisions"])
      assert employee_doctor.id == contractor_employee_divisions["employee"]["databaseId"]
      assert division.id == contractor_employee_divisions["division"]["databaseId"]
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
          :contract_request,
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

      drfo_signed_content(content, legal_entity.edrpou, party_user.party.last_name)

      resp_body =
        conn
        |> put_client_id(legal_entity.id)
        |> put_consumer_id(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> put_scope("contract_request:update")
        |> post_query(@decline_query, input_signed_content(content))
        |> json_response(200)

      resp_contract_request = get_in(resp_body, ~w(data declineContractRequest contractRequest))

      assert ContractRequest.status(:declined) == resp_contract_request["status"]
      contractor_employee_divisions = hd(resp_contract_request["contractorEmployeeDivisions"])
      assert employee_doctor.id == contractor_employee_divisions["employee"]["databaseId"]
      assert division.id == contractor_employee_divisions["division"]["databaseId"]

      contract_request = Repo.get(ContractRequest, contract_request.id)
      assert contract_request.status_reason == "Не відповідає попереднім домовленостям"
      assert contract_request.nhs_signer_id == user_id
      assert contract_request.nhs_legal_entity_id == legal_entity.id

      contract_request_id = contract_request.id
      contract_request_status = contract_request.status
      assert event = EventManagerRepo.one(Event)

      assert %Event{
               entity_type: "ContractRequest",
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
        :contract_request,
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
      data = Map.put(data, "printout_content", printout_content)

      drfo_signed_content(data, [
        %{drfo: legal_entity.edrpou, surname: nhs_signer_party.last_name},
        %{drfo: legal_entity.edrpou, surname: nhs_signer_party.last_name, is_stamp: true}
      ])

      variables = %{
        input: %{
          id: Node.to_global_id("ContractRequest", id),
          signedContent: %{
            content: data |> Jason.encode!() |> Base.encode64(),
            encoding: "BASE64"
          }
        }
      }

      resp_body =
        conn
        |> put_scope("contract_request:sign")
        |> put_consumer_id(user_id)
        |> put_client_id(client_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post_query(@sign_query, variables)
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
      contract_request = insert(:il, :contract_request, status: @contract_request_status_new)

      id = Node.to_global_id("ContractRequest", contract_request.id)
      employee_id = Node.to_global_id("Employee", employee.id)

      variables = %{input: %{id: id, employeeId: employee_id}}

      resp_body =
        conn
        |> put_consumer_id()
        |> put_client_id(legal_entity.id)
        |> post_query(@assign_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data assignContractRequest contractRequest))

      assert nil == resp_body["errors"]
      assert id == resp_entity["id"]
      assert @contract_request_status_in_process == resp_entity["status"]
      assert employee_id == resp_entity["assignee"]["id"]
    end
  end

  defp input_signed_content(content) do
    %{
      input: %{
        signedContent: %{
          content: content |> Jason.encode!() |> Base.encode64(),
          encoding: "BASE64"
        }
      }
    }
  end
end
