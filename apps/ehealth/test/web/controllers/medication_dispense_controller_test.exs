defmodule EHealth.Web.MedicationDispenseControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Core.Contracts.ReimbursementContract
  alias Core.LegalEntities.LegalEntity
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.UUID

  setup :verify_on_exit!

  describe "create medication dispense" do
    setup %{conn: conn} do
      msp()
      {:ok, %{conn: conn}}
    end

    test "invalid legal_entity", %{conn: conn} do
      legal_entity_id = UUID.generate()
      conn = put_client_id_header(conn, legal_entity_id)
      conn = post(conn, medication_dispense_path(conn, :create), medication_dispense: new_dispense_params())
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.legal_entity_id"}]}} = resp
    end

    test "invalid legal_entity mis_verified", %{conn: conn} do
      %{user_id: user_id} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity, mis_verified: LegalEntity.mis_verified(:not_verified))

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> Plug.Conn.put_req_header(consumer_id_header(), user_id)
        |> post(medication_dispense_path(conn, :create), medication_dispense: new_dispense_params())
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Legal entity is not verified"
    end

    test "invalid medication_request", %{conn: conn} do
      %{user_id: user_id} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      {medication_request, _} = build_resp(%{legal_entity_id: legal_entity.id})

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense: new_dispense_params(%{medication_request_id: UUID.generate()})
        )

      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.medication_request_id"}]}} = resp
    end

    test "medication_request is not active", %{conn: conn} do
      %{user_id: user_id} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          medication_request_params: %{
            status: "EXPIRED"
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense: new_dispense_params()
        )

      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Medication request is not active"}} = resp
    end

    test "invalid medication dispense period", %{conn: conn} do
      %{user_id: user_id} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense: new_dispense_params()
        )

      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Invalid dispense period"}} = resp
    end

    test "invalid party", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(medication_dispense_path(conn, :create), medication_dispense: new_dispense_params())
        |> json_response(400)

      assert %{"error" => %{"message" => "Party not found"}} = resp
    end

    test "no active employee", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity, is_active: false)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medical_program_id} = insert(:prm, :medical_program)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post(conn, medication_dispense_path(conn, :create), medication_dispense: new_dispense_params())
      assert json_response(conn, 403)
    end

    test "invalid division", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, is_active: false, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medical_program_id} = insert(:prm, :medical_program)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post(conn, medication_dispense_path(conn, :create), medication_dispense: new_dispense_params())
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.division_id"}]}} = resp
    end

    test "division is not active", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, is_active: false, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medical_program_id} = insert(:prm, :medical_program, is_active: true)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id
            })
        )

      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Division is not active"}} = resp
    end

    test "invalid division dls status", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity, dls_verified: nil)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medical_program_id} = insert(:prm, :medical_program, is_active: true)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id
            })
        )

      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Invalid division dls status"}} = resp
    end

    test "invalid medical program", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medical_program_id} = insert(:prm, :medical_program, is_active: true)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: UUID.generate()
            })
        )

      resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.medical_program_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Medical program not found",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "medical program is not active", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program, is_active: false)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: medical_program_id,
              dispense_details: [
                %{
                  medication_id: medication_id,
                  medication_qty: 10,
                  sell_price: 18.65,
                  sell_amount: 186.5,
                  discount_amount: 150
                }
              ]
            })
        )

      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Medical program is not active"}} = resp
    end

    test "no active contract exists (medical program)", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> Plug.Conn.put_req_header(consumer_id_header(), user_id)
        |> post(
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: medical_program_id,
              dispense_details: [
                %{
                  medication_id: medication_id,
                  medication_qty: 10,
                  sell_price: 18.65,
                  sell_amount: 186.5,
                  discount_amount: 150
                }
              ]
            })
        )
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Program cannot be used - no active contract exists"
    end

    test "medical program in dispense does not match the one in medication request", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program, is_active: true)
      %{id: medical_program_id_request} = insert(:prm, :medical_program, is_active: true)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: medical_program_id_request
            })
        )

      resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.medical_program_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Medical program in dispense doesn't match the one in medication request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "invalid medication", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      medical_program = insert(:prm, :medical_program, is_active: true)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      contract =
        insert(:prm, :reimbursement_contract,
          status: ReimbursementContract.status(:verified),
          contractor_legal_entity: legal_entity,
          contractor_legal_entity_id: legal_entity.id,
          medical_program: medical_program
        )

      insert(:prm, :contract_division, contract_id: contract.id, division_id: division_id)

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: medical_program.id,
              dispense_details: [
                %{
                  medication_id: UUID.generate(),
                  medication_qty: 10,
                  sell_price: 18.65,
                  sell_amount: 186.5,
                  discount_amount: 50
                }
              ]
            })
        )

      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.dispense_details[0].medication_id"}]}} = resp
    end

    test "division is not belong to contract", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      %{id: innm_dosage_id} = insert_innm_dosage()
      medical_program = insert(:prm, :medical_program, is_active: true)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      insert(:prm, :reimbursement_contract,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity,
        contractor_legal_entity_id: legal_entity.id,
        medical_program: medical_program
      )

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      request_data = %{
        medication_dispense: new_dispense_params(%{division_id: division_id, medical_program_id: medical_program.id})
      }

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> post(medication_dispense_path(conn, :create), request_data)
        |> json_response(409)

      assert %{"error" => %{"type" => "request_conflict"}} = resp
    end

    test "medication is not active", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      medical_program = insert(:prm, :medical_program, is_active: true)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      contract =
        insert(:prm, :reimbursement_contract,
          status: ReimbursementContract.status(:verified),
          contractor_legal_entity: legal_entity,
          contractor_legal_entity_id: legal_entity.id,
          medical_program: medical_program
        )

      insert(:prm, :contract_division, contract_id: contract.id, division_id: division_id)

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: medical_program.id
            })
        )

      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.dispense_details[0].medication_id"}]}} = resp
    end

    test "medication is not a participant of program", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program, is_active: true)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      contract =
        insert(:prm, :reimbursement_contract,
          status: ReimbursementContract.status(:verified),
          contractor_legal_entity: legal_entity,
          contractor_legal_entity_id: legal_entity.id,
          medical_program: medical_program
        )

      insert(:prm, :contract_division, contract_id: contract.id, division_id: division_id)

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: medical_program.id,
              dispense_details: [
                %{
                  medication_id: medication_id,
                  medication_qty: 10,
                  sell_price: 18.65,
                  sell_amount: 186.5,
                  discount_amount: 50
                }
              ]
            })
        )

      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.dispense_details[0].medication_id"}]}} = resp
    end

    test "invalid code", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program, is_active: true)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        medical_program_id: medical_program.id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      contract =
        insert(:prm, :reimbursement_contract,
          status: ReimbursementContract.status(:verified),
          contractor_legal_entity: legal_entity,
          contractor_legal_entity_id: legal_entity.id,
          medical_program: medical_program
        )

      insert(:prm, :contract_division, contract_id: contract.id, division_id: division_id)

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: medical_program.id,
              dispense_details: [
                %{
                  medication_id: medication_id,
                  medication_qty: 10,
                  sell_price: 18.65,
                  sell_amount: 186.5,
                  discount_amount: 50
                }
              ]
            })
        )

      assert json_response(conn, 401)
    end

    test "requested reimbursement is higher than allowed", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program, is_active: true)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        medical_program_id: medical_program.id
      )

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          }
        })

      contract =
        insert(:prm, :reimbursement_contract,
          status: ReimbursementContract.status(:verified),
          contractor_legal_entity: legal_entity,
          contractor_legal_entity_id: legal_entity.id,
          medical_program: medical_program
        )

      insert(:prm, :contract_division, contract_id: contract.id, division_id: division_id)

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)

      conn =
        post(
          conn,
          medication_dispense_path(conn, :create),
          code: "1234",
          medication_dispense:
            new_dispense_params(%{
              division_id: division_id,
              medical_program_id: medical_program.id,
              dispense_details: [
                %{
                  medication_id: medication_id,
                  medication_qty: 10,
                  sell_price: 18.65,
                  sell_amount: 186.5,
                  discount_amount: 150
                }
              ]
            })
        )

      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.dispense_details[0].discount_amount"}]}} = resp
    end

    test "failed when medication request intent is PLAN", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity, is_active: false)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medical_program_id} = insert(:prm, :medical_program)

      contract = insert(:prm, :reimbursement_contract)
      insert(:prm, :contract_division, contract_id: contract.id, division_id: division_id)

      {medication_request, _} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1),
            intent: MedicationRequest.intent(:plan)
          }
        })

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> Plug.Conn.put_req_header(consumer_id_header(), user_id)
        |> post(medication_dispense_path(conn, :create), medication_dispense: new_dispense_params())
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Medication request with intent PLAN cannot be dispensed"
    end

    test "success create medication dispense in devitaion koeficient", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program, is_active: true)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        medical_program_id: medical_program.id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {medication_request, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1),
            medication_qty: 110,
            verification_code: "1234"
          },
          medication_dispense_params: %{
            party_id: party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication_id,
            medication_qty: 100,
            sell_price: 18.65,
            sell_amount: 1865,
            discount_amount: 450
          }
        })

      contract =
        insert(:prm, :reimbursement_contract,
          status: ReimbursementContract.status(:verified),
          contractor_legal_entity: legal_entity,
          contractor_legal_entity_id: legal_entity.id,
          medical_program: medical_program
        )

      insert(:prm, :contract_division, contract_id: contract.id, division_id: division_id)

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      expect(OPSMock, :create_medication_dispense, fn _params, _headers ->
        {:ok, %{"data" => medication_dispense}}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(OPSMock, :get_qualify_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_id]}}
      end)

      create_data = %{
        code: "1234",
        medication_dispense:
          new_dispense_params(%{
            division_id: division_id,
            medical_program_id: medical_program.id,
            dispense_details: [
              %{
                medication_id: medication_id,
                medication_qty: 100,
                sell_price: 18.65,
                sell_amount: 1865,
                discount_amount: 450
              }
            ]
          })
      }

      conn
      |> put_client_id_header(legal_entity.id)
      |> Plug.Conn.put_req_header(consumer_id_header(), user_id)
      |> post(medication_dispense_path(conn, :create), create_data)
      |> json_response(201)
      |> assert_show_response_schema("medication_dispense")
    end

    test "success create medication dispense", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program, is_active: true)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        medical_program_id: medical_program.id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {medication_request, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1),
            medication_qty: 10,
            verification_code: "1234"
          },
          medication_dispense_params: %{
            party_id: party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      contract =
        insert(:prm, :reimbursement_contract,
          status: ReimbursementContract.status(:verified),
          contractor_legal_entity: legal_entity,
          contractor_legal_entity_id: legal_entity.id,
          medical_program: medical_program
        )

      insert(:prm, :contract_division, contract_id: contract.id, division_id: division_id)

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      expect(OPSMock, :create_medication_dispense, fn _params, _headers ->
        {:ok, %{"data" => medication_dispense}}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(OPSMock, :get_qualify_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_id]}}
      end)

      create_data = %{
        code: "1234",
        medication_dispense:
          new_dispense_params(%{
            division_id: division_id,
            medical_program_id: medical_program.id,
            dispense_details: [
              %{
                medication_id: medication_id,
                medication_qty: 10,
                sell_price: 18.65,
                sell_amount: 186.5,
                discount_amount: 50
              }
            ]
          })
      }

      conn
      |> put_client_id_header(legal_entity.id)
      |> Plug.Conn.put_req_header(consumer_id_header(), user_id)
      |> post(medication_dispense_path(conn, :create), create_data)
      |> json_response(201)
      |> assert_show_response_schema("medication_dispense")
    end

    test "success create medication dispense without program_id", %{conn: conn} do
      expect_mpi_get_person()

      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program, is_active: true)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        medical_program_id: medical_program.id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {medication_request, medication_dispense} =
        build_resp(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            medication_id: innm_dosage_id,
            medication_request_params: %{
              dispense_valid_from: Date.utc_today() |> Date.add(-1),
              dispense_valid_to: Date.utc_today() |> Date.add(1),
              medication_qty: 10,
              verification_code: "1234"
            },
            medication_dispense_params: %{
              party_id: party.id
            },
            medication_dispense_details_params: %{
              medication_id: medication_id,
              medication_qty: 10,
              sell_price: 18.65,
              sell_amount: 186.5,
              discount_amount: 50
            }
          },
          true
        )

      insert(:prm, :reimbursement_contract,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity,
        contractor_legal_entity_id: legal_entity.id,
        medical_program: medical_program
      )

      expect(OPSMock, :get_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      expect(OPSMock, :create_medication_dispense, fn _params, _headers ->
        {:ok, %{"data" => medication_dispense}}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      create_data = %{
        code: "1234",
        medication_dispense:
          new_dispense_params(%{
            division_id: division_id,
            dispense_details: [
              %{
                medication_id: medication_id,
                medication_qty: 10,
                sell_price: 18.65,
                sell_amount: 186.5,
                discount_amount: 50
              }
            ]
          })
          |> Map.delete(:medical_program_id)
      }

      conn
      |> put_client_id_header(legal_entity.id)
      |> Plug.Conn.put_req_header(consumer_id_header(), user_id)
      |> post(medication_dispense_path(conn, :create), create_data)
      |> json_response(201)
      |> assert_show_response_schema("medication_dispense")
    end
  end

  describe "show medication dispense" do
    setup %{conn: conn} do
      msp()
      {:ok, %{conn: conn}}
    end

    test "success show by id", %{conn: conn} do
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      conn
      |> put_client_id_header(legal_entity.id)
      |> get(medication_dispense_path(conn, :show, medication_dispense["id"]))
      |> json_response(200)
      |> assert_show_response_schema("medication_dispense")
    end

    test "success show by id without medical_program", %{conn: conn} do
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)

      {_, medication_dispense} =
        build_resp(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            medical_program_id: UUID.generate(),
            medication_id: innm_dosage_id,
            medication_request_params: %{
              dispense_valid_from: Date.utc_today() |> Date.add(-1),
              dispense_valid_to: Date.utc_today() |> Date.add(1)
            },
            medication_dispense_params: %{
              party_id: party.id
            },
            medication_dispense_details_params: %{
              medication_id: medication.id,
              division_id: division.id
            }
          },
          true
        )

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      conn
      |> put_client_id_header(legal_entity.id)
      |> get(medication_dispense_path(conn, :show, medication_dispense["id"]))
      |> json_response(200)
      |> assert_show_response_schema("medication_dispense")
    end
  end

  describe "list medication dispenses" do
    setup %{conn: conn} do
      msp()
      {:ok, %{conn: conn}}
    end

    test "success list", %{conn: conn} do
      expect_mpi_get_person()

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program, is_active: true)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication_id,
            division_id: division_id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn
      |> put_client_id_header(legal_entity.id)
      |> get(medication_dispense_path(conn, :index))
      |> json_response(200)
      |> assert_list_response_schema("medication_dispense")
    end

    test "success list medication dispenses without medical_program", %{conn: conn} do
      expect_mpi_get_person()

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      %{id: division_id} =
        insert(
          :prm,
          :division,
          is_active: true,
          legal_entity: legal_entity
        )

      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {_, medication_dispense} =
        build_resp(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            medication_id: innm_dosage_id,
            medication_request_params: %{
              dispense_valid_from: Date.utc_today() |> Date.add(-1),
              dispense_valid_to: Date.utc_today() |> Date.add(1)
            },
            medication_dispense_params: %{
              party_id: party.id
            },
            medication_dispense_details_params: %{
              medication_id: medication_id,
              division_id: division_id
            }
          },
          true
        )

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn
      |> put_client_id_header(legal_entity.id)
      |> get(medication_dispense_path(conn, :index))
      |> json_response(200)
      |> assert_list_response_schema("medication_dispense")
    end
  end

  describe "process medication dispense" do
    test "success process", %{conn: conn} do
      msp(2)

      person = string_params_for(:person)

      expect(MPIMock, :person, 2, fn _, _headers ->
        {:ok, %{"data" => person}}
      end)

      party_user = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      insert(
        :prm,
        :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {medication_request, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party_user.party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            medication: medication,
            division_id: division_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :update_medication_request, fn _id, _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      expect(OPSMock, :update_medication_dispense, fn _id, %{"medication_dispense" => params}, _headers ->
        {:ok, %{"data" => Map.merge(medication_dispense, params)}}
      end)

      expect(OPSMock, :get_medication_dispenses, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      payment_id = "12345"
      payment_amount = 20

      content =
        conn
        |> put_client_id_header(legal_entity.id)
        |> get(medication_dispense_path(conn, :show, medication_dispense["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.merge(%{
          "payment_id" => payment_id,
          "payment_amount" => payment_amount
        })

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => content,
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity.edrpou,
                   "drfo" => party_user.party.tax_id,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            content
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(200)
        |> assert_show_response_schema("medication_dispense")
        |> Map.get("data")

      assert "PROCESSED" == resp["status"]
      assert payment_id == resp["payment_id"]
      assert payment_amount == resp["payment_amount"]
    end

    test "invalid division dls status", %{conn: conn} do
      msp(2)
      person = string_params_for(:person)

      expect(MPIMock, :person, 2, fn _, _headers ->
        {:ok, %{"data" => person}}
      end)

      party_user = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity, dls_verified: nil)
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      insert(
        :prm,
        :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party_user.party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            medication: medication,
            division_id: division_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :get_medication_dispenses, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      payment_id = "12345"
      payment_amount = 20

      content =
        conn
        |> put_client_id_header(legal_entity.id)
        |> get(medication_dispense_path(conn, :show, medication_dispense["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.merge(%{
          "payment_id" => payment_id,
          "payment_amount" => payment_amount
        })

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => content,
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity.edrpou,
                   "drfo" => party_user.party.tax_id,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            content
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(409)

      assert "Invalid division dls status" == resp["error"]["message"]
    end

    test "fail to find medication dispense", %{conn: conn} do
      msp()

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 0,
             "total_pages" => 1
           }
         }}
      end)

      assert conn
             |> put_client_id_header(UUID.generate())
             |> patch(medication_dispense_path(conn, :process, UUID.generate()), %{
               "signed_medication_dispense" =>
                 %{}
                 |> Jason.encode!()
                 |> Base.encode64(),
               "signed_content_encoding" => "base64"
             })
             |> json_response(404)
    end

    test "invalid legal_entity_id", %{conn: conn} do
      msp()

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            medication_request_id: UUID.generate(),
            medication_request: nil,
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      assert conn
             |> put_client_id_header(UUID.generate())
             |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
               "signed_medication_dispense" =>
                 %{}
                 |> Jason.encode!()
                 |> Base.encode64(),
               "signed_content_encoding" => "base64"
             })
             |> json_response(404)
    end

    test "invalid transition", %{conn: conn} do
      msp()
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      party_user = insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id,
            status: "EXPIRED"
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => %{},
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity.edrpou,
                   "drfo" => party_user.party.tax_id,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(409)

      assert resp["error"]["message"] =~ "Can't update medication dispense status from"
    end

    test "invalid request params", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> patch(medication_dispense_path(conn, :process, UUID.generate()), %{"test" => "test"})
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.signed_medication_dispense",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "required property signed_medication_dispense was not present",
                       "rule" => "required"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.signed_content_encoding",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "required property signed_content_encoding was not present",
                       "rule" => "required"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "invalid payment params", %{conn: conn} do
      msp(4)
      expect_mpi_get_person(4)

      party_user = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      insert(
        :prm,
        :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party_user.party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            medication: medication,
            division_id: division_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :get_medication_dispenses, 4, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      content =
        conn
        |> put_client_id_header(legal_entity.id)
        |> get(medication_dispense_path(conn, :show, medication_dispense["id"]))
        |> json_response(200)
        |> Map.get("data")

      expect(SignatureMock, :decode_and_validate, 3, fn content, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => content |> Base.decode64!() |> Jason.decode!(),
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity.edrpou,
                   "drfo" => party_user.party.tax_id,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      endpoint_call = fn content ->
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" => content,
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)
      end

      resp =
        endpoint_call.(
          content
          |> Map.drop(~w(payment_id payment_amount))
          |> Jason.encode!()
          |> Base.encode64()
        )

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.payment_amount",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "required property payment_amount was not present",
                       "rule" => "required"
                     }
                   ]
                 }
               ]
             } = resp["error"]

      resp =
        endpoint_call.(
          content
          |> Map.merge(%{
            "payment_id" => 12_345,
            "payment_amount" => "test"
          })
          |> Jason.encode!()
          |> Base.encode64()
        )

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.payment_amount",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "type mismatch. Expected number but got string",
                       "rule" => "cast"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.payment_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "type mismatch. Expected string, null but got integer",
                       "rule" => "cast"
                     }
                   ]
                 }
               ]
             } = resp["error"]

      resp =
        endpoint_call.(
          content
          |> Map.merge(%{
            "payment_id" => "12345",
            "payment_amount" => -1
          })
          |> Jason.encode!()
          |> Base.encode64()
        )

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.payment_amount",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "expected the value to be >= 0",
                       "params" => %{"greater_than_or_equal_to" => 0},
                       "raw_description" => "expected the value to be >= %{greater_than_or_equal_to}",
                       "rule" => "number"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "invalid user in DS: drfo", %{conn: conn} do
      msp()
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      party_user = insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id,
            status: "EXPIRED"
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => %{},
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity.edrpou,
                   "drfo" => "test",
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{"message" => "Does not match the signer drfo"} = resp["error"]
    end

    test "invalid user in DS: drfo is absent", %{conn: conn} do
      msp()
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      party_user = insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id,
            status: "EXPIRED"
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => %{},
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity.edrpou,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
               ]
             } = resp["error"]
    end

    test "invalid user in DS: surname", %{conn: conn} do
      msp()
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      party_user = insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id,
            status: "EXPIRED"
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => %{},
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity.edrpou,
                   "drfo" => party_user.party.tax_id,
                   "surname" => "test"
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
               ],
               "message" => "Does not match the signer last name",
               "type" => "request_malformed"
             } = resp["error"]
    end

    test "invalid legal entity in DS", %{conn: conn} do
      msp()
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      party_user = insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id,
            status: "EXPIRED"
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => %{},
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => "test",
                   "drfo" => party_user.party.tax_id,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
               ],
               "message" => "Does not match the legal entity",
               "type" => "request_malformed"
             } = resp["error"]
    end

    test "legal entity in DS as absent", %{conn: conn} do
      msp()
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      party_user = insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id,
            status: "EXPIRED"
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => %{},
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "drfo" => party_user.party.tax_id,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
               ],
               "message" => "Invalid edrpou",
               "type" => "request_malformed"
             } = resp["error"]
    end

    test "failed to process by NOT owner", %{conn: conn} do
      msp()

      legal_entity_action = insert(:prm, :legal_entity)
      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      party_user = insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id,
            status: "EXPIRED"
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      assert conn
             |> put_client_id_header(legal_entity_action.id)
             |> put_consumer_id_header(party_user.user_id)
             |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
               "signed_medication_dispense" =>
                 %{}
                 |> Jason.encode!()
                 |> Base.encode64(),
               "signed_content_encoding" => "base64"
             })
             |> json_response(404)
    end

    test "success process by NHS", %{conn: conn} do
      nhs(2)

      person = string_params_for(:person)

      expect(MPIMock, :person, 2, fn _, _headers ->
        {:ok, %{"data" => person}}
      end)

      party_user = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      legal_entity_action = insert(:prm, :legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity_action)

      insert(
        :prm,
        :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {medication_request, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party_user.party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            medication: medication,
            division_id: division_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :update_medication_request, fn _id, _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      expect(OPSMock, :update_medication_dispense, fn _id, %{"medication_dispense" => params}, _headers ->
        {:ok, %{"data" => Map.merge(medication_dispense, params)}}
      end)

      expect(OPSMock, :get_medication_dispenses, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      payment_id = "12345"
      payment_amount = 20

      content =
        conn
        |> put_client_id_header(legal_entity_action.id)
        |> get(medication_dispense_path(conn, :show, medication_dispense["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.merge(%{
          "payment_id" => payment_id,
          "payment_amount" => payment_amount
        })

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => content,
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity_action.edrpou,
                   "drfo" => party_user.party.tax_id,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity_action.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            content
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(200)
        |> assert_show_response_schema("medication_dispense")
        |> Map.get("data")

      assert "PROCESSED" == resp["status"]
      assert payment_id == resp["payment_id"]
      assert payment_amount == resp["payment_amount"]
    end

    test "failed when signed content does not match the previously created content", %{conn: conn} do
      msp(2)

      person = string_params_for(:person)

      expect(MPIMock, :person, 2, fn _, _headers ->
        {:ok, %{"data" => person}}
      end)

      party_user = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      insert(
        :prm,
        :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party_user.party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            medication: medication,
            division_id: division_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :get_medication_dispenses, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      content =
        conn
        |> put_client_id_header(legal_entity.id)
        |> get(medication_dispense_path(conn, :show, medication_dispense["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.put("updated_by", UUID.generate())

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => content,
             "signatures" => [
               %{
                 "is_valid" => true,
                 "is_stamp" => false,
                 "signer" => %{
                   "edrpou" => legal_entity.edrpou,
                   "drfo" => party_user.party.tax_id,
                   "surname" => party_user.party.last_name
                 }
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> patch(medication_dispense_path(conn, :process, medication_dispense["id"]), %{
          "signed_medication_dispense" =>
            content
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.content",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Signed content does not match the previously created content",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end
  end

  describe "reject medication dispense" do
    setup %{conn: conn} do
      msp()
      {:ok, %{conn: conn}}
    end

    test "success reject", %{conn: conn} do
      expect_mpi_get_person()

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      insert(
        :prm,
        :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      payment_id = "12345"

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1),
            medication_qty: 10,
            verification_code: "1234"
          },
          medication_dispense_params: %{
            party_id: party.id,
            payment_id: payment_id
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            medication: medication,
            division_id: division_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :update_medication_dispense, fn _id, _params, _headers ->
        {:ok, %{"data" => Map.put(medication_dispense, "status", "REJECTED")}}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      path = medication_dispense_path(conn, :reject, medication_dispense["id"])

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> patch(path, %{"payment_id" => payment_id})
        |> json_response(200)
        |> assert_show_response_schema("medication_dispense")
        |> Map.get("data")

      assert "REJECTED" == resp["status"]
      assert payment_id == resp["payment_id"]
    end

    test "success reject medication dispense without medical_program", %{conn: conn} do
      expect_mpi_get_person()

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)

      insert(
        :prm,
        :program_medication,
        medication_id: medication.id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      payment_id = "12345"

      {_, medication_dispense} =
        build_resp(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            medication_id: innm_dosage_id,
            medication_request_params: %{
              dispense_valid_from: Date.utc_today() |> Date.add(-1),
              dispense_valid_to: Date.utc_today() |> Date.add(1),
              medication_qty: 10,
              verification_code: "1234"
            },
            medication_dispense_params: %{
              party_id: party.id,
              payment_id: payment_id
            },
            medication_dispense_details_params: %{
              medication_id: medication.id,
              medication: medication,
              division_id: division_id,
              medication_qty: 10,
              sell_price: 18.65,
              sell_amount: 186.5,
              discount_amount: 50
            }
          },
          true
        )

      expect(OPSMock, :update_medication_dispense, fn _id, _params, _headers ->
        {:ok, %{"data" => Map.put(medication_dispense, "status", "REJECTED")}}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_dispense],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      path = medication_dispense_path(conn, :reject, medication_dispense["id"])

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> patch(path, %{"payment_id" => payment_id})
        |> json_response(200)
        |> assert_show_response_schema("medication_dispense")
        |> Map.get("data")

      assert "REJECTED" == resp["status"]
      assert payment_id == resp["payment_id"]
    end

    test "fail to find medication dispense", %{conn: conn} do
      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 0,
             "total_pages" => 1
           }
         }}
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, medication_dispense_path(conn, :reject, UUID.generate()))
      assert json_response(conn, 404)
    end

    test "invalid legal_entity_id", %{conn: conn} do
      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: medication_id} = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      insert(
        :prm,
        :program_medication,
        medication_id: medication_id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division_id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_request_params: %{
            medication_request_id: UUID.generate(),
            medication_request: nil,
            dispense_valid_from: Date.utc_today() |> Date.add(-1),
            dispense_valid_to: Date.utc_today() |> Date.add(1)
          },
          medication_dispense_params: %{
            party_id: party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication_id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, medication_dispense_path(conn, :reject, medication_dispense["id"]))
      assert json_response(conn, 404)
    end

    test "invalid transition", %{conn: conn} do
      expect_mpi_get_person()

      legal_entity = insert(:prm, :legal_entity)
      medication = insert(:prm, :medication)
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      insert_medication(innm_dosage_id)
      medical_program = insert(:prm, :medical_program)

      {_, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program.id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id,
            status: "EXPIRED"
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            division_id: division.id
          }
        })

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      path = medication_dispense_path(conn, :reject, medication_dispense["id"])
      conn = patch(conn, path, %{"payment_id" => "12345"})
      assert json_response(conn, 409)
    end
  end

  describe "list by medication_request_id" do
    setup %{conn: conn} do
      msp()
      {:ok, %{conn: conn}}
    end

    test "success list", %{conn: conn} do
      expect_mpi_get_person()

      party = insert(:prm, :party)
      %{user_id: user_id, party: party} = insert(:prm, :party_user, party: party)
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity, division: division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      insert(
        :prm,
        :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )

      {medication_request, medication_dispense} =
        build_resp(%{
          legal_entity_id: legal_entity.id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          medication_dispense_params: %{
            party_id: party.id
          },
          medication_dispense_details_params: %{
            medication_id: medication.id,
            medication: medication,
            division_id: division.id,
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 50
          }
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_request]}}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok, %{"data" => [medication_dispense]}}
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> get(medication_dispense_path(conn, :by_medication_request, medication_request["id"]))
        |> json_response(200)
        |> assert_list_response_schema("medication_dispense")
        |> Map.get("data")

      assert 1 == length(resp)
      assert medication_request["id"] == resp |> hd() |> get_in(~w(medication_request id))
    end

    test "party_user not found", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, medication_dispense_path(conn, :by_medication_request, UUID.generate()))
      assert json_response(conn, 500)
    end
  end

  defp expect_mpi_get_person(n \\ 1) do
    expect(MPIMock, :person, n, fn id, _headers ->
      {:ok, %{"data" => string_params_for(:person, id: id)}}
    end)
  end

  defp new_dispense_params(params \\ %{}) do
    Map.merge(
      %{
        medication_request_id: UUID.generate(),
        dispensed_at: Date.utc_today() |> Date.to_string(),
        dispensed_by: "John Doe #{:rand.uniform(100)}",
        division_id: UUID.generate(),
        medical_program_id: UUID.generate(),
        dispense_details: [
          %{
            medication_id: UUID.generate(),
            medication_qty: 10,
            sell_price: 18.65,
            sell_amount: 186.5,
            discount_amount: 150
          }
        ]
      },
      params
    )
  end

  defp insert_medication(innm_dosage_id) do
    id = UUID.generate()

    insert(
      :prm,
      :medication,
      id: id,
      ingredients: [
        build(
          :ingredient_medication,
          medication_child_id: innm_dosage_id,
          parent_id: id
        )
      ]
    )
  end

  def insert_innm_dosage do
    %{id: innm_id} = insert(:prm, :innm)

    innm_dosage =
      insert(
        :prm,
        :innm_dosage
      )

    insert(
      :prm,
      :ingredient_innm_dosage,
      innm_child_id: innm_id,
      parent_id: innm_dosage.id
    )

    innm_dosage
  end

  defp build_resp(params, exclude_medical_program \\ false) do
    general_params =
      params
      |> Enum.filter(fn {k, _} ->
        k not in [:medication_request_params, :medication_dispense_params, :medication_dispense_details_params]
      end)
      |> Enum.into(%{})

    medication_request_params = Map.merge(general_params, Map.get(params, :medication_request_params, %{}))
    medication_request = build(:medication_request, medication_request_params)

    medication_request =
      if exclude_medical_program do
        Map.put(medication_request, :medical_program_id, nil)
      else
        medication_request
      end

    medication_dispense_params =
      %{
        medication_request_id: medication_request["id"],
        medication_request: medication_request
      }
      |> Map.merge(general_params)
      |> Map.merge(Map.get(params, :medication_dispense_params, %{}))

    medication_dispense = build(:medication_dispense, medication_dispense_params)

    medication_dispense =
      if exclude_medical_program do
        Map.put(medication_dispense, :medical_program_id, nil)
      else
        medication_dispense
      end

    medication_dispense_details_params =
      %{
        medication_dispense_id: medication_dispense.id
      }
      |> Map.merge(Map.get(params, :medication_dispense_details_params, %{}))

    medication_dispense_details = build(:medication_dispense_details, medication_dispense_details_params)

    medication_dispense =
      medication_dispense
      |> Map.put(:medication_request_id, medication_request.id)
      |> Map.put(:details, [medication_dispense_details])
      |> Jason.encode!()
      |> Jason.decode!()

    medication_request =
      medication_request
      |> Jason.encode!()
      |> Jason.decode!()

    {medication_request, medication_dispense}
  end
end
