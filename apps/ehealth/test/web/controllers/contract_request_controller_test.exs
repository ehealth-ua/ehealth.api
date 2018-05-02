defmodule EHealth.Web.ContractRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Mox
  import EHealth.MockServer, only: [get_client_admin: 0]

  alias EHealth.ContractRequests.ContractRequest
  alias EHealth.Employees.Employee
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Utils.NumberGenerator
  alias Ecto.UUID
  alias EHealth.EventManagerRepo
  alias EHealth.EventManager.Event
  import Mox
  import EHealth.MockServer, only: [get_client_admin: 0]

  @contract_request_status_new ContractRequest.status(:new)
  @contract_request_status_declined ContractRequest.status(:declined)

  describe "create contract request" do
    test "user is not owner", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee} = prepare_data("DOCTOR")
      params = prepare_params(legal_entity, division, employee)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, contract_request_path(conn, :create), params)
      assert json_response(conn, 403)
    end

    test "employee division is not active", %{conn: conn} do
      %{legal_entity: legal_entity, employee: employee} = prepare_data()
      division = insert(:prm, :division)
      conn = put_client_id_header(conn, legal_entity.id)
      params = prepare_params(legal_entity, division, employee)
      conn = post(conn, contract_request_path(conn, :create), params)
      resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.contractor_employee_divisions[0].division_id",
        "Division must be active and within current legal_entity"
      )
    end

    test "external contractor division is not present in employee divisions", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee} = prepare_data()
      conn = put_client_id_header(conn, legal_entity.id)

      params =
        legal_entity
        |> prepare_params(division, employee)
        |> Map.delete("external_contractor_flag")
        |> Map.put("external_contractors", [
          %{"divisions" => [%{"id" => UUID.generate()}]}
        ])

      conn = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.external_contractors[0].divisions[0].id",
        "The division is not belong to contractor_employee_divisions"
      )
    end

    test "invalid expires_at date", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee} = prepare_data()
      conn = put_client_id_header(conn, legal_entity.id)

      params =
        legal_entity
        |> prepare_params(division, employee, "2018-01-01")
        |> Map.put("start_date", "2018-02-01")
        |> Map.delete("external_contractor_flag")

      conn = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.external_contractors[0].contract.expires_at",
        "Expires date must be greater than contract start_date"
      )
    end

    test "invalid external_contractor_flag", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee} = prepare_data()
      conn = put_client_id_header(conn, legal_entity.id)

      params =
        legal_entity
        |> prepare_params(division, employee, "2018-03-01")
        |> Map.put("start_date", "2018-02-01")
        |> Map.delete("external_contractor_flag")

      conn = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn, 422)
      assert_error(resp, "$.external_contractor_flag", "Invalid external_contractor_flag")
    end

    test "start_date is in the past", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee} = prepare_data()
      conn = put_client_id_header(conn, legal_entity.id)

      params =
        legal_entity
        |> prepare_params(division, employee, "2018-03-01")
        |> Map.put("start_date", "2018-02-01")

      conn = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn, 422)
      assert_error(resp, "$.start_date", "Start date must be greater than create date")
    end

    test "start_date is too far in the future", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee} = prepare_data()
      conn = put_client_id_header(conn, legal_entity.id)
      now = Date.utc_today()
      start_date = Date.add(now, 3650)

      params =
        legal_entity
        |> prepare_params(division, employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("start_date", Date.to_iso8601(start_date))

      conn = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn, 422)
      assert_error(resp, "$.start_date", "Start date must be within this or next year")
    end

    test "invalid end_date", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee} = prepare_data()
      conn = put_client_id_header(conn, legal_entity.id)
      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        legal_entity
        |> prepare_params(division, employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 365 * 3)))

      conn = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn, 422)
      assert_error(resp, "$.end_date", "The year of start_date and and date must be equal")
    end

    test "invalid contractor_owner_id", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee} = prepare_data()
      conn = put_client_id_header(conn, legal_entity.id)
      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        legal_entity
        |> prepare_params(division, employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 30)))

      conn = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.contractor_owner_id",
        "Contractor owner must be active within current legal entity in contract request"
      )
    end

    test "invalid contract number", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee, user_id: user_id, owner: owner} =
        prepare_data()

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        legal_entity
        |> prepare_params(division, employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.put("contract_number", "invalid")
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 30)))

      conn = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.contract_number",
        "string does not match pattern \"^\\\\d{4}-[\\\\dAEHKMPTX]{4}-[\\\\dAEHKMPTX]{4}$\"",
        "format"
      )
    end

    test "success create contract request with contract_number", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee, user_id: user_id, owner: owner} =
        prepare_data()

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        legal_entity
        |> prepare_params(division, employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.put("contract_number", NumberGenerator.generate_from_sequence(1, 1))
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 30)))

      conn1 = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn1, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "success create contract request without contract_number", %{conn: conn} do
      %{legal_entity: legal_entity, division: division, employee: employee, user_id: user_id, owner: owner} =
        prepare_data()

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        legal_entity
        |> prepare_params(division, employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 30)))

      conn1 = post(conn, contract_request_path(conn, :create), params)
      assert resp = json_response(conn1, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "update contract_request" do
    test "user is not NHS ADMIN SIGNER", %{conn: conn} do
      contract_request = insert(:il, :contract_request)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "OWNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :update, contract_request.id), %{
          "nhs_signer_base" => "на підставі наказу",
          "nhs_contract_price" => 50_000,
          "nhs_payment_method" => "prepayment"
        })

      assert json_response(conn, 403)
    end

    test "no contract_request found", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :update, UUID.generate()), %{
          "nhs_signer_base" => "на підставі наказу",
          "nhs_contract_price" => 50_000,
          "nhs_payment_method" => "prepayment"
        })

      assert json_response(conn, 404)
    end

    test "contract_request has wrong status", %{conn: conn} do
      contract_request = insert(:il, :contract_request, status: ContractRequest.status(:signed))

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :update, contract_request.id), %{
          "nhs_signer_base" => "на підставі наказу",
          "nhs_contract_price" => 50_000,
          "nhs_payment_method" => "prepayment"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
               ],
               "message" => "Incorrect status of contract_request to modify it",
               "type" => "request_malformed"
             } = resp["error"]
    end

    test "success update contract_request", %{conn: conn} do
      contract_request = insert(:il, :contract_request)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :update, contract_request.id), %{
          "nhs_signer_base" => "на підставі наказу",
          "nhs_contract_price" => 50_000,
          "nhs_payment_method" => "prepayment"
        })

      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "show contract_request details" do
    setup %{conn: conn} do
      %{id: legal_entity_id_1} = insert(:prm, :legal_entity, type: "MSP")
      %{id: contract_request_id_1} = insert(:il, :contract_request, contractor_legal_entity_id: legal_entity_id_1)

      %{id: legal_entity_id_2} = insert(:prm, :legal_entity, type: "MSP")
      %{id: contract_request_id_2} = insert(:il, :contract_request, contractor_legal_entity_id: legal_entity_id_2)

      {:ok,
       %{
         conn: conn,
         legal_entity_id_1: legal_entity_id_1,
         contract_request_id_1: contract_request_id_1,
         contract_request_id_2: contract_request_id_2
       }}
    end

    test "success showing data for correct MPS client", %{conn: conn} = context do
      assert conn
             |> put_client_id_header(context.legal_entity_id_1)
             |> get(contract_request_path(conn, :show, context.contract_request_id_1))
             |> json_response(200)
    end

    test "denied showing data for uncorrect MPS client", %{conn: conn} = context do
      assert conn
             |> put_client_id_header(context.legal_entity_id_1)
             |> get(contract_request_path(conn, :show, context.contract_request_id_2))
             |> json_response(403)
    end

    test "contract_request not found", %{conn: conn} = context do
      assert conn
             |> put_client_id_header(context.legal_entity_id_1)
             |> get(contract_request_path(conn, :show, UUID.generate()))
             |> json_response(404)
    end

    test "success showing any contract_request for NHS ADMIN client", %{conn: conn} = context do
      assert conn
             |> put_client_id_header(get_client_admin())
             |> get(contract_request_path(conn, :show, context.contract_request_id_1))
             |> json_response(200)

      assert conn
             |> put_client_id_header(get_client_admin())
             |> get(contract_request_path(conn, :show, context.contract_request_id_2))
             |> json_response(200)
    end

    test "contract_request not found for NHS ADMIN client", %{conn: conn} do
      assert conn
             |> put_client_id_header(get_client_admin())
             |> get(contract_request_path(conn, :show, UUID.generate()))
             |> json_response(404)
    end
  end

  describe "approve contract_request" do
    test "user is not NHS ADMIN SIGNER", %{conn: conn} do
      contract_request = insert(:il, :contract_request)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "OWNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert json_response(conn, 403)
    end

    test "no contract_request found", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, UUID.generate()))
      assert json_response(conn, 404)
    end

    test "contract_request has wrong status", %{conn: conn} do
      contract_request = insert(:il, :contract_request, status: ContractRequest.status(:signed))

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
               ],
               "message" => "Incorrect status of contract_request to modify it",
               "type" => "request_malformed"
             } = resp["error"]
    end

    test "contractor_legal_entity not found", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      contract_request = insert(:il, :contract_request, contractor_legal_entity_id: UUID.generate())
      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_legal_entity_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Legal entity not found",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "contractor_legal_entity is not active", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity, status: LegalEntity.status(:closed))
      contract_request = insert(:il, :contract_request, contractor_legal_entity_id: legal_entity.id)
      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_legal_entity_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Legal entity in contract request should be active",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "contractor_owner_id not found", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: UUID.generate()
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_owner_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "Contractor owner must be active within current legal entity in contract request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "contractor_owner_id has invalid status", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, status: Employee.status(:new))

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_owner_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "Contractor owner must be active within current legal entity in contract request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "employee legal_entity_id doesn't match contractor_legal_entity_id", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_owner_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "Contractor owner must be active within current legal entity in contract request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "employee is not owner", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity_id: legal_entity.id)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_owner_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "Contractor owner must be active within current legal entity in contract request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "external contractor division is not present in employee divisions", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user, user_id: user_id)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id,
          contractor_employee_divisions: [
            %{division_id: UUID.generate(), employee_id: employee.id}
          ]
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_employee_divisions.employee_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Employee must be active DOCTOR with linked division",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "invalid start date", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user, user_id: user_id)

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
      now = Date.utc_today()
      start_date = Date.add(now, 3650)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          start_date: start_date,
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ]
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.start_date",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Start date must be within this or next year",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "success approve contract request", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, "<html></html>"}
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

      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)
      now = Date.utc_today()
      start_date = Date.add(now, 10)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
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

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      conn = patch(conn, contract_request_path(conn, :approve, contract_request.id))
      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "terminate contract_request" do
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

      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      contract_request =
        insert(
          :il,
          :contract_request,
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

      {:ok,
       %{
         conn: conn,
         user_id: user_id,
         legal_entity: legal_entity,
         contract_request: contract_request
       }}
    end

    test "success contract_request terminating", %{
      conn: conn,
      user_id: user_id,
      legal_entity: legal_entity,
      contract_request: contract_request
    } do
      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])

      assert resp["data"]["status"] == ContractRequest.status(:terminated)
      assert resp["data"]["updated_by"] == user_id
    end

    test "contract_request not found", %{
      conn: conn,
      user_id: user_id,
      legal_entity: legal_entity
    } do
      assert conn
             |> put_client_id_header(legal_entity.id)
             |> put_consumer_id_header(user_id)
             |> patch(contract_request_path(conn, :terminate, UUID.generate()), %{
               "status_reason" => "Неправильний період контракту"
             })
             |> json_response(404)
    end

    test "legal_entity_id doesn't match contractor_legal_entity_id", %{
      conn: conn,
      legal_entity: legal_entity
    } do
      contract_request = insert(:il, :contract_request, contractor_legal_entity_id: UUID.generate())
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "User is not allowed to perform this action"} = resp["error"]
    end

    test "employee legal_entity_id doesn't match contractor_legal_entity_id", %{
      conn: conn,
      legal_entity: legal_entity
    } do
      employee = insert(:prm, :employee)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "User is not allowed to perform this action"} = resp["error"]
    end

    test "employee is not owner", %{
      conn: conn,
      legal_entity: legal_entity
    } do
      employee = insert(:prm, :employee, legal_entity_id: legal_entity.id)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "User is not allowed to perform this action"} = resp["error"]
    end

    test "contract_request has wrong status", %{
      conn: conn,
      user_id: user_id,
      legal_entity: legal_entity,
      contract_request: contract_request
    } do
      contract_request = EHealth.Repo.get(ContractRequest, contract_request.id)
      contract_request = Ecto.Changeset.change(contract_request, status: ContractRequest.status(:signed))
      {:ok, contract_request} = EHealth.Repo.update(contract_request)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
               ],
               "message" => "Incorrect status of contract_request to modify it",
               "type" => "request_malformed"
             } = resp["error"]
    end

    test "event manager successful registration", %{
      conn: conn,
      user_id: user_id,
      legal_entity: legal_entity,
      contract_request: contract_request
    } do
      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert json_response(conn, 200)

      contract_request_id = contract_request.id
      contract_request_status = ContractRequest.status(:terminated)

      assert event = EventManagerRepo.one(Event)

      assert %Event{
               entity_type: "ContractRequest",
               event_type: "StatusChangeEvent",
               entity_id: ^contract_request_id,
               properties: %{"status" => %{"new_value" => ^contract_request_status}}
             } = event
    end
  end

  describe "search contract request" do
    setup do
      nhs_signer_id = UUID.generate()
      contract_number = UUID.generate()
      contractor_owner_id = UUID.generate()
      legal_entity_id_1 = UUID.generate()
      legal_entity_id_2 = get_client_admin()

      insert(:prm, :legal_entity, type: "MSP", id: legal_entity_id_1)
      insert(:prm, :legal_entity, type: "NHS ADMIN", id: legal_entity_id_2)
      insert(:il, :contract_request, %{issue_city: "Львів"})

      insert(:il, :contract_request, %{
        issue_city: "Київ",
        contractor_legal_entity_id: legal_entity_id_1,
        contract_number: contract_number
      })

      insert(:il, :contract_request, %{
        issue_city: "Київ",
        contractor_legal_entity_id: legal_entity_id_1,
        nhs_signer_id: nhs_signer_id
      })

      insert(:il, :contract_request, %{
        issue_city: "Львів",
        contractor_legal_entity_id: legal_entity_id_1,
        status: ContractRequest.status(:declined)
      })

      insert(:il, :contract_request, %{
        issue_city: "Київ",
        contractor_legal_entity_id: legal_entity_id_2,
        contractor_owner_id: contractor_owner_id
      })

      insert(:il, :contract_request, %{
        issue_city: "Львів",
        nhs_signer_id: nhs_signer_id,
        status: ContractRequest.status(:signed)
      })

      {:ok,
       %{
         nhs_signer_id: nhs_signer_id,
         contract_number: contract_number,
         contractor_owner_id: contractor_owner_id,
         legal_entity_id_1: legal_entity_id_1,
         legal_entity_id_2: legal_entity_id_2
       }}
    end

    test "finds by status from different client types", %{
      conn: conn,
      legal_entity_id_1: legal_entity_id_1,
      legal_entity_id_2: legal_entity_id_2
    } do
      %{"data" => response_data} = do_get_contract_request(conn, legal_entity_id_1, %{"status" => "New"})
      assert [%{"status" => @contract_request_status_new}, _] = response_data

      %{"data" => response_data} = do_get_contract_request(conn, legal_entity_id_2, %{"status" => "new"})
      assert 4 === length(response_data)

      %{"data" => response_data} =
        do_get_contract_request(conn, legal_entity_id_1, %{"issue_city" => "ЛЬВІВ", "status" => "declined"})

      assert [%{"status" => @contract_request_status_declined}] = response_data
    end

    test "finds by issue city", %{conn: conn, legal_entity_id_1: legal_entity_id_1} do
      %{"data" => response_data} = do_get_contract_request(conn, legal_entity_id_1, %{"issue_city" => "КИЇВ"})
      assert 2 === length(response_data)
    end

    test "finds by attributtes", %{
      conn: conn,
      contractor_owner_id: contractor_owner_id,
      nhs_signer_id: nhs_signer_id,
      contract_number: contract_number,
      legal_entity_id_1: legal_entity_id_1,
      legal_entity_id_2: legal_entity_id_2
    } do
      %{"data" => response_data} =
        do_get_contract_request(conn, legal_entity_id_2, %{"contractor_owner_id" => contractor_owner_id})

      assert [%{"contractor_owner_id" => ^contractor_owner_id}] = response_data

      %{"data" => response_data} = do_get_contract_request(conn, legal_entity_id_2, %{"nhs_signer_id" => nhs_signer_id})

      assert [%{"nhs_signer_id" => ^nhs_signer_id}, _] = response_data

      %{"data" => response_data} =
        do_get_contract_request(conn, legal_entity_id_1, %{"contract_number" => contract_number})

      assert [%{"contract_number" => ^contract_number}] = response_data

      %{"data" => response_data} =
        do_get_contract_request(conn, legal_entity_id_1, %{"contractor_legal_entity_id" => legal_entity_id_1})

      assert [%{"contractor_legal_entity_id" => ^legal_entity_id_1}, _, _] = response_data
    end

    test "finds nothing", %{conn: conn, legal_entity_id_1: legal_entity_id_1} do
      assert %{"data" => []} = do_get_contract_request(conn, legal_entity_id_1, %{"contract_number" => UUID.generate()})
    end
  end

  defp do_get_contract_request(conn, client_id, search_params) do
    conn =
      conn
      |> put_client_id_header(client_id)
      |> get(contract_request_path(conn, :index), search_params)

    json_response(conn, 200)
  end

  describe "sign nhs" do
    test "no contract_request found", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, contract_request_path(conn, :sign_nhs, UUID.generate()))
      assert json_response(conn, 404)
    end

    test "invalid client_id", %{conn: conn} do
      contract_request = insert(:il, :contract_request)
      conn = put_client_id_header(conn, get_client_admin())

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => "",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "Invalid client_id", "type" => "forbidden"} = resp["error"]
    end

    test "party_user not found", %{conn: conn} do
      client_id = get_client_admin()
      contract_request = insert(:il, :contract_request, nhs_legal_entity_id: client_id)
      conn = put_client_id_header(conn, client_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => "",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert %{"message" => "Employee is not allowed to sign"} = resp["error"]
    end

    test "valid employee not found", %{conn: conn} do
      client_id = get_client_admin()
      user_id = UUID.generate()
      insert(:prm, :party_user, user_id: user_id)
      contract_request = insert(:il, :contract_request, nhs_legal_entity_id: client_id)

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => "",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "Employee is not allowed to sign")
    end

    test "contract_request already signed", %{conn: conn} do
      %{"client_id" => client_id, "user_id" => user_id, "contract_request" => contract_request} =
        prepare_nhs_sign_params(nhs_signed: true)

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => "",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "The contract was already signed by NHS")
    end

    test "failed to decode signed content", %{conn: conn} do
      %{"client_id" => client_id, "user_id" => user_id, "contract_request" => contract_request} =
        prepare_nhs_sign_params()

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => "invalid",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert %{"is_valid" => false} == resp["error"]
    end

    test "content doesn't match", %{conn: conn} do
      %{"client_id" => client_id, "user_id" => user_id, "contract_request" => contract_request} =
        prepare_nhs_sign_params()

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      data = %{"id" => contract_request.id, "printout_content" => "<html></html>"}

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "Signed content does not match the previously created content")
    end

    test "invalid status", %{conn: conn} do
      id = UUID.generate()
      data = %{"id" => id, "printout_content" => "<html></html>"}

      %{"client_id" => client_id, "user_id" => user_id, "contract_request" => contract_request} =
        prepare_nhs_sign_params(id: id, data: data)

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "Incorrect status of contract_request to modify it")
    end

    test "failed to save signed content", %{conn: conn} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _ ->
        {:error, "failed to save content"}
      end)

      id = UUID.generate()
      data = %{"id" => id, "printout_content" => "<html></html>"}

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ContractRequest.status(:approved)
        )

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 502)
      assert %{"message" => "Failed to save signed content"} = resp["error"]
    end

    test "success to sign contract_request", %{conn: conn} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _ ->
        {:ok, "success"}
      end)

      id = UUID.generate()
      data = %{"id" => id, "printout_content" => "<html></html>"}

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ContractRequest.status(:approved)
        )

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  defp prepare_data(role_name \\ "OWNER") do
    expect(MithrilMock, :get_user_roles, fn _, _, _ ->
      {:ok, %{"data" => [%{"role_name" => role_name}]}}
    end)

    user_id = UUID.generate()
    party_user = insert(:prm, :party_user, user_id: user_id)
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)

    employee =
      insert(
        :prm,
        :employee,
        division: division,
        legal_entity_id: legal_entity.id
      )

    owner =
      insert(
        :prm,
        :employee,
        employee_type: Employee.type(:owner),
        party: party_user.party,
        legal_entity_id: legal_entity.id
      )

    %{legal_entity: legal_entity, employee: employee, division: division, user_id: user_id, owner: owner}
  end

  defp prepare_params(legal_entity, division, employee, expires_at \\ nil) do
    %{
      "contractor_owner_id" => UUID.generate(),
      "contractor_base" => "на підставі закону про Медичне обслуговування населення",
      "contractor_payment_details" => %{
        "bank_name" => "Банк номер 1",
        "MFO" => "351005",
        "payer_account" => "32009102701026"
      },
      "contractor_legal_entity_id" => legal_entity.id,
      "contractor_rmsp_amount" => 10,
      "id_form" => "5",
      "contractor_employee_divisions" => [
        %{
          "employee_id" => employee.id,
          "staff_units" => 0.5,
          "declaration_limit" => 2000,
          "division_id" => division.id
        }
      ],
      "external_contractors" => [
        %{
          "divisions" => [%{"id" => division.id}],
          "contract" => %{"expires_at" => expires_at}
        }
      ],
      "external_contractor_flag" => true,
      "start_date" => "2018-01-01",
      "end_date" => "2018-01-01"
    }
  end

  defp prepare_nhs_sign_params(contract_request_params \\ [], legal_entity_params \\ []) do
    client_id = get_client_admin()
    params = Keyword.merge([id: client_id], legal_entity_params)
    legal_entity = insert(:prm, :legal_entity, params)
    user_id = UUID.generate()
    nhs_signer_id = Keyword.get(contract_request_params, :nhs_signer_id) || UUID.generate()
    party_user = insert(:prm, :party_user, user_id: user_id)
    insert(:prm, :employee, party: party_user.party, legal_entity_id: client_id, id: nhs_signer_id)
    division = insert(:prm, :division, legal_entity: legal_entity)
    employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

    employee_owner =
      insert(
        :prm,
        :employee,
        id: user_id,
        legal_entity_id: legal_entity.id,
        employee_type: Employee.type(:owner),
        party: party_user.party
      )

    now = Date.utc_today()
    start_date = Date.add(now, 10)

    params =
      Keyword.merge(
        [
          nhs_legal_entity_id: client_id,
          nhs_signer_id: user_id,
          contractor_legal_entity_id: client_id,
          contractor_owner_id: employee_owner.id,
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ],
          start_date: start_date
        ],
        contract_request_params
      )

    contract_request = insert(:il, :contract_request, params)

    %{
      "client_id" => client_id,
      "user_id" => user_id,
      "legal_entity" => legal_entity,
      "party_user" => party_user,
      "contract_request" => contract_request
    }
  end

  defp assert_error(resp, message) do
    assert %{
             "invalid" => [
               %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
             ],
             "message" => ^message,
             "type" => "request_malformed"
           } = resp["error"]
  end

  defp assert_error(resp, entry, description, rule \\ "invalid") do
    assert %{
             "type" => "validation_failed",
             "invalid" => [
               %{
                 "rules" => [
                   %{
                     "rule" => ^rule,
                     "description" => ^description
                   }
                 ],
                 "entry_type" => "json_data_property",
                 "entry" => ^entry
               }
             ]
           } = resp["error"]
  end
end
