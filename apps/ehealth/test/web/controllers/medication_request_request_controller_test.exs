defmodule EHealth.Web.MedicationRequestRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Core.Expectations.OtpVerification
  import Core.Expectations.RPC
  import Core.Expectations.Signature
  import Mox

  alias Core.GlobalParameters
  alias Core.MedicationRequestRequest
  alias Core.MedicationRequestRequests
  alias Core.PRMRepo
  alias Core.Repo
  alias Core.Rpc.Error, as: RpcError
  alias Core.Utils.Phone
  alias Ecto.Changeset
  alias Ecto.UUID
  alias EHealth.MockServer

  setup :verify_on_exit!

  @legal_entity_id "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
  @medication_request_request_data_fields ~w(
    created_at
    started_at
    ended_at
    dispense_valid_from
    dispense_valid_to
    person_id
    employee_id
    division_id
    medication_id
    legal_entity_id
    medication_qty
    medical_program_id
    intent
    category
    context
    dosage_instruction
  )a

  def fixture(:medication_request_request, params \\ %{}, exclude_medical_program_id \\ false) do
    {medication_id, pm} = create_medications_structure()

    test_request =
      test_request(%{
        "medication_id" => medication_id,
        "medical_program_id" => pm.medical_program_id
      })
      |> Map.merge(params)

    test_request =
      if exclude_medical_program_id do
        Map.delete(test_request, "medical_program_id")
      else
        test_request
      end

    {:ok, medication_request_request, _} =
      MedicationRequestRequests.create(
        test_request,
        "7488a646-e31f-11e4-aace-600308960662",
        @legal_entity_id
      )

    mrr_update_params =
      medication_request_request
      |> Map.get(:medication_request_request)
      |> Map.from_struct()
      |> Map.get(:data)
      |> Map.take(~w(person_id employee_id intent)a)

    updated_mrr =
      medication_request_request.medication_request_request
      |> Changeset.change(%{
        data_person_id: mrr_update_params.person_id,
        data_employee_id: mrr_update_params.employee_id,
        data_intent: mrr_update_params.intent
      })
      |> Repo.update!()

    %{medication_request_request | medication_request_request: updated_mrr}
  end

  setup %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity, id: @legal_entity_id)

    division =
      insert(
        :prm,
        :division,
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        legal_entity: legal_entity,
        is_active: true
      )

    employee =
      insert(
        :prm,
        :employee,
        id: "7488a646-e31f-11e4-aace-600308960662",
        legal_entity: legal_entity,
        division: division
      )

    party_id = employee.party |> Map.get(:id)
    user_id = Ecto.UUID.generate()
    PRMRepo.insert!(%Core.PartyUsers.PartyUser{user_id: user_id, party_id: party_id})

    insert(:il, :dictionary,
      name: "eHealth/SNOMED/additional_dosage_instructions",
      values: %{"311504000" => ""}
    )

    insert(:il, :dictionary, name: "eHealth/timing_abbreviation", values: %{"patient" => ""})

    insert(:il, :dictionary,
      name: "eHealth/SNOMED/anatomical_structure_administration_site_codes",
      values: %{"344001" => ""}
    )

    insert(:il, :dictionary, name: "eHealth/SNOMED/route_codes", values: %{"46713006" => ""})

    insert(:il, :dictionary,
      name: "eHealth/SNOMED/administration_methods",
      values: %{"419747000" => ""}
    )

    insert(:il, :dictionary, name: "eHealth/dose_and_rate", values: %{"ordered" => ""})

    conn =
      conn
      |> put_consumer_id_header(user_id)
      |> put_client_id_header(legal_entity.id)

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all medication_request_requests", %{conn: conn} do
      conn = get(conn, medication_request_request_path(conn, :index, %{}))
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all medication_request_requests with data", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_mpi_get_person()

      mrr = fixture(:medication_request_request)
      data = %{"employee_id" => mrr.medication_request_request.data.employee_id}

      assert 1 =
               conn
               |> get(medication_request_request_path(conn, :index, data))
               |> json_response(200)
               |> Map.get("data")
               |> assert_list_response_schema("medication_request_request")
               |> length
    end

    test "lists all medication_request_requests with data with different intents", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")
      expect_mpi_get_person(2)
      expect_ops_get_declarations()

      fixture(:medication_request_request, %{"intent" => "order"})
      fixture(:medication_request_request, %{"intent" => "plan"}, true)

      assert 2 =
               conn
               |> get(medication_request_request_path(conn, :index, %{}))
               |> json_response(200)
               |> Map.get("data")
               |> assert_list_response_schema("medication_request_request")
               |> length
    end

    test "lists all medication_request_requests with data search by status", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_mpi_get_person()

      fixture(:medication_request_request)

      assert 1 =
               conn
               |> get(medication_request_request_path(conn, :index, %{"status" => "NEW"}))
               |> json_response(200)
               |> Map.get("data")
               |> assert_list_response_schema("medication_request_request")
               |> length
    end

    test "lists all medication_request_requests with data search by person_id", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_mpi_get_person()

      mrr = fixture(:medication_request_request)
      data = %{"person_id" => mrr.medication_request_request.data.person_id}

      assert 1 =
               conn
               |> get(medication_request_request_path(conn, :index, data))
               |> json_response(200)
               |> Map.get("data")
               |> assert_list_response_schema("medication_request_request")
               |> length
    end

    test "lists all medication_request_requests with data search by all posible filters", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_mpi_get_person()

      mrr = fixture(:medication_request_request, %{"intent" => "order"})

      data = %{
        "person_id" => mrr.medication_request_request.data.person_id,
        "employee_id" => mrr.medication_request_request.data.employee_id,
        "status" => "NEW",
        "intent" => "order"
      }

      assert 1 =
               conn
               |> get(medication_request_request_path(conn, :index, data))
               |> json_response(200)
               |> Map.get("data")
               |> assert_list_response_schema("medication_request_request")
               |> length
    end

    test "lists all medication_request_requests with data search by intent", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations(2)
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_mpi_get_person()
      expect_encounter_status("finished")
      expect_mpi_get_person()

      %{medication_request_request: %{id: mrr_id_in}} = fixture(:medication_request_request, %{"intent" => "order"})

      %{medication_request_request: %{id: mrr_id_out}} =
        fixture(:medication_request_request, %{"intent" => "plan"}, true)

      resp =
        conn
        |> get(medication_request_request_path(conn, :index, %{"intent" => "order"}))
        |> json_response(200)
        |> Map.get("data")

      assert_list_response_schema(resp, "medication_request_request")
      assert length(resp) == 1
      assert mrr_id_in == resp |> Enum.at(0) |> Map.get("id")
      refute mrr_id_out == resp |> Enum.at(0) |> Map.get("id")
    end

    test "ignore invalid search params", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations(2)
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_mpi_get_person()
      expect_encounter_status("finished")
      expect_mpi_get_person(2)

      fixture(:medication_request_request, %{"intent" => "order"})
      fixture(:medication_request_request, %{"intent" => "plan"}, true)

      assert 2 ==
               conn
               |> get(medication_request_request_path(conn, :index, %{"test" => 12345}))
               |> json_response(200)
               |> Map.get("data")
               |> assert_list_response_schema("medication_request_request")
               |> length()
    end

    test "failed when search params values is invalid", %{conn: conn} do
      resp =
        conn
        |> get(
          medication_request_request_path(conn, :index, %{
            "person_id" => "test",
            "employee_id" => 12345
          })
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.employee_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "is invalid",
                       "params" => ["Elixir.Ecto.UUID"],
                       "rule" => "cast"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.person_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "is invalid",
                       "params" => ["Elixir.Ecto.UUID"],
                       "rule" => "cast"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end
  end

  describe "show medication_request_request" do
    test "success", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_mpi_get_person()

      %{medication_request_request: %{id: id}} = fixture(:medication_request_request)

      conn = get(conn, medication_request_request_path(conn, :show, id))
      resp = json_response(conn, 200)
      assert resp["data"]["id"] == id
    end

    test "success when PLAN data does not contain medical_program_id", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations()
      expect_encounter_status("finished")
      expect_mpi_get_person()

      %{medication_request_request: %{id: id}} = fixture(:medication_request_request, %{"intent" => "plan"}, true)

      resp =
        conn
        |> get(medication_request_request_path(conn, :show, id))
        |> json_response(200)
        |> Map.get("data")

      assert_show_response_schema(
        resp,
        "medication_request_request",
        "medication_request_request_plan"
      )

      assert resp["id"] == id
    end

    test "invalid request id", %{conn: conn} do
      id = Ecto.UUID.generate()
      conn = get(conn, medication_request_request_path(conn, :show, id))
      assert json_response(conn, 404)
    end
  end

  describe "create medication_request_request" do
    test "fails with addtional request params", %{conn: conn} do
      test_request =
        %{"medication_id" => UUID.generate(), "medical_program_id" => UUID.generate()}
        |> test_request()
        |> Map.put("programs", %{id: UUID.generate()})

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert [%{"entry" => "$.programs"}] = resp["error"]["invalid"]
    end

    test "render medication_request_request when data is valid", %{conn: conn} do
      person = build(:person)
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_ops_get_declarations()

      expect_ops_last_medication_request_dates(%{
        "started_at" => Date.add(Date.utc_today(), -2),
        "ended_at" => Date.add(Date.utc_today(), -1)
      })

      expect_encounter_status("finished")
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(201)

      assert %{"id" => id} =
               resp
               |> Map.get("data")
               |> assert_show_response_schema("medication_request_request")

      assert person
             |> Map.get(:authentication_methods, [])
             |> List.first()
             |> filter_authentication_method() == get_in(resp, ~w(urgent authentication_method_current))

      conn
      |> get(medication_request_request_path(conn, :show, id))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("medication_request_request")

      medication_request_request_data =
        MedicationRequestRequest
        |> Repo.get!(id)
        |> Map.get(:data)

      Enum.each(@medication_request_request_data_fields, fn field ->
        assert Map.has_key?(medication_request_request_data, field)
      end)
    end

    test "success when medical_program is absent (medical_program param is optional)", %{conn: conn} do
      person = build(:person)
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_ops_get_declarations()
      expect_encounter_status("finished")
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)

      {medication_id, _} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "intent" => "order"
        })
        |> Map.delete("medical_program_id")

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(201)

      assert %{"id" => id} =
               resp
               |> Map.get("data")
               |> assert_show_response_schema("medication_request_request")

      assert person
             |> Map.get(:authentication_methods, [])
             |> List.first()
             |> filter_authentication_method() == get_in(resp, ~w(urgent authentication_method_current))

      conn
      |> get(medication_request_request_path(conn, :show, id))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("medication_request_request")

      medication_request_request_data =
        MedicationRequestRequest
        |> Repo.get!(id)
        |> Map.get(:data)

      Enum.each(@medication_request_request_data_fields -- [:medical_program_id], fn field ->
        assert Map.has_key?(medication_request_request_data, field)
      end)
    end

    test "invalid request params", %{conn: conn} do
      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request:
            test_request(%{
              "dispense_valid_from" => Date.utc_today() |> Date.to_string(),
              "dispense_valid_to" => Date.utc_today() |> Date.to_string()
            })
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.dispense_valid_from",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "schema does not allow additional properties",
                       "rule" => "schema"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.dispense_valid_to",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "schema does not allow additional properties",
                       "rule" => "schema"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "invalid created_at parameter", %{conn: conn} do
      expect_mpi_get_person()
      {medication_id, pm} = create_medications_structure()

      medication_request_request_delay_input = Confex.fetch_env!(:core, :medication_request_request)[:delay_input]

      created_at =
        Date.utc_today()
        |> Date.add(-(medication_request_request_delay_input + 1))
        |> Date.to_string()

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id,
          "created_at" => created_at,
          "started_at" => Date.utc_today() |> to_string(),
          "ended_at" => Date.utc_today() |> Date.add(medication_dispense_period) |> Date.to_string()
        })

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.created_at",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Create date must be >= Current date - MRR delay input!",
                       "params" => [],
                       "rule" => nil
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "render medication_request_request when PLAN data does not contain medical_program_id", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")

      {medication_id, _} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "intent" => "plan"
        })
        |> Map.delete("medical_program_id")

      assert conn
             |> post(medication_request_request_path(conn, :create),
               medication_request_request: test_request
             )
             |> json_response(201)
             |> Map.get("data")
             |> assert_show_response_schema(
               "medication_request_request",
               "medication_request_request_plan"
             )
    end

    test "render medication_request_request when optional fields are absent", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()

      expect_ops_last_medication_request_dates(nil)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })
        |> Map.drop(~w(context dosage_instruction))

      assert conn
             |> post(medication_request_request_path(conn, :create),
               medication_request_request: test_request
             )
             |> json_response(201)
             |> Map.get("data")
             |> assert_show_response_schema("medication_request_request")
    end

    test "render errors when request data is invalid", %{conn: conn} do
      resp =
        conn
        |> post(medication_request_request_path(conn, :create), medication_request_request: %{})
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.intent",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "required property intent was not present",
                       "rule" => "required"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "render errors when person_id is invalid", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> nil end)
      test_request = test_request(%{"person_id" => "585041f5-1272-4bca-8d41-8440eefe7d26"})

      assert resp =
               conn
               |> post(medication_request_request_path(conn, :create), medication_request_request: test_request)
               |> json_response(422)

      assert List.first(resp["error"]["invalid"])["entry"] == "$.data.person_id"
    end

    test "render errors when employee_id is invalid", %{conn: conn} do
      test_request = test_request(%{"employee_id" => "585041f5-1272-4bca-8d41-8440eefe7d26"})

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.employee_id"
    end

    test "render errors when division_id is invalid", %{conn: conn} do
      expect_mpi_get_person()

      test_request = test_request(%{"division_id" => "585041f5-1272-4bca-8d41-8440eefe7d26"})

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.division_id"
    end

    test "render errors when declaration doesn't exists", %{conn: conn} do
      expect(OPSMock, :get_declarations, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect_mpi_get_person()

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "person_id" => "575041f5-1272-4bca-8d41-8440eefe7d26",
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      error_message =
        conn
        |> json_response(422)
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("rules")
        |> List.first()
        |> Map.get("description")

      assert error_message == "Only doctors with an active declaration with the patient can create medication request!"
    end

    test "render errors when ended_at < started_at", %{conn: conn} do
      expect_mpi_get_person()
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id,
          "ended_at" => Timex.today() |> Timex.shift(days: 2) |> to_string(),
          "started_at" => Timex.today() |> Timex.shift(days: 3) |> to_string()
        })

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.ended_at"
    end

    test "render errors when started_at < created_at", %{conn: conn} do
      expect_mpi_get_person()
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id,
          "started_at" => Timex.today() |> Timex.shift(days: 2) |> to_string(),
          "created_at" => Timex.today() |> Timex.shift(days: 3) |> to_string()
        })

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.started_at"
    end

    test "render errors when started_at < today", %{conn: conn} do
      expect_mpi_get_person()
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id,
          "started_at" => Timex.today() |> Timex.shift(days: -2) |> to_string()
        })

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.started_at"
    end

    test "render errors when medication doesn't exists", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)

      {_, pm} = create_medications_structure()
      {medication_id1, _} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id1,
          "medical_program_id" => pm.medical_program_id
        })

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      error_msg =
        conn
        |> json_response(422)
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("rules")
        |> List.first()
        |> Map.get("description")

      assert error_msg == "Not found any medications allowed for create medication request for this medical program!"
    end

    test "render errors when medication_qty is invalid", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medication_qty" => 7,
          "medical_program_id" => pm.medical_program_id
        })

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      error_msg =
        conn
        |> json_response(422)
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("rules")
        |> List.first()
        |> Map.get("description")

      assert error_msg ==
               "The amount of medications in medication request must be divisible to package minimum quantity"
    end

    test "render medication_request_request when medication created with different qty", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")

      {medication_id, pm} = create_medications_structure()

      %{id: med_id1} =
        insert(
          :prm,
          :medication,
          name: "Бупропіонол TEST",
          package_qty: 20,
          package_min_qty: 10
        )

      insert(:prm, :ingredient_medication, parent_id: med_id1, medication_child_id: medication_id)

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medication_qty" => 5,
          "medical_program_id" => pm.medical_program_id
        })

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 201)
    end

    test "render errors when medication_program is invalid", %{conn: conn} do
      expect_mpi_get_person()

      {medication_id, _} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => Ecto.UUID.generate()
        })

      conn = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert json_response(conn, 422)

      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.medical_program_id"
    end

    test "render errors when request ORDER data is invalid", %{conn: conn} do
      test_request =
        test_request(%{
          "intent" => "order",
          "medication_id" => UUID.generate(),
          "context" => %{
            "identifier" => %{
              "type" => %{
                "coding" => %{
                  "system" => "eHealth/resources",
                  "code" => "encounter"
                }
              },
              value: "9183a36b-4d45-4244-9339-63d81cd08d9c"
            }
          }
        })
        |> Map.drop(~w(medical_program_id category))

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.context.identifier.type.coding",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "type mismatch. Expected array but got object",
                       "rule" => "cast"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.category",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "required property category was not present",
                       "rule" => "required"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "render errors when request PLAN data is invalid", %{conn: conn} do
      test_request =
        test_request(%{
          "intent" => "plan",
          "medication_id" => UUID.generate(),
          "context" => %{
            "identifier" => %{
              "type" => %{
                "coding" => %{
                  "system" => "eHealth/resources",
                  "code" => "encounter"
                }
              },
              value: "9183a36b-4d45-4244-9339-63d81cd08d9c"
            }
          }
        })
        |> Map.drop(~w(medical_program_id category))

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.context.identifier.type.coding",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "type mismatch. Expected array but got object",
                       "rule" => "cast"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.category",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "required property category was not present",
                       "rule" => "required"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "render errors when context coding type is invalid", %{conn: conn} do
      test_request =
        test_request(%{
          "medication_id" => UUID.generate(),
          "medical_program_id" => UUID.generate(),
          "context" => %{
            "identifier" => %{
              "type" => %{
                "coding" => [
                  %{
                    "system" => "eHealth/resources",
                    "code" => "test"
                  }
                ]
              },
              value: "9183a36b-4d45-4244-9339-63d81cd08d9c"
            }
          }
        })

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.context.identifier.type.coding.[0].code",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "value is not allowed in enum",
                       "params" => %{"values" => ["encounter"]},
                       "rule" => "inclusion"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "render errors when context encounter status is invalid", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("entered_in_error")

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.context",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Entity in status \"entered-in-error\" can not be referenced",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "render errors when context encounter not found", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status(nil)
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.context",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Entity not found",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "render errors when sequence is not unique within dosage instruction array", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      dosage_instruction = Map.get(test_request, "dosage_instruction")
      dosage_instruction_item = hd(dosage_instruction)

      test_request = Map.put(test_request, "dosage_instruction", [dosage_instruction_item | dosage_instruction])

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.dosage_instruction",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Sequence must be unique",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "render errors when dosage instruction entry code is not valid in dictionary", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_ops_get_declarations(2)
      expect_encounter_status("finished")
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      dosage_instruction = Map.get(test_request, "dosage_instruction")

      endpoint_call = fn request ->
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: request
        )
        |> json_response(422)
      end

      # additional_instruction testing

      dosage_instruction_item =
        dosage_instruction
        |> hd()
        |> Map.merge(%{
          "sequence" => 2,
          "additional_instruction" => [
            %{
              "coding" => [
                %{
                  "system" => "eHealth/SNOMED/additional_dosage_instructions",
                  "code" => "311504000"
                }
              ]
            },
            %{
              "coding" => [
                %{
                  "system" => "eHealth/SNOMED/additional_dosage_instructions",
                  "code" => "311504000"
                },
                %{
                  "system" => "eHealth/SNOMED/additional_dosage_instructions",
                  "code" => "test"
                }
              ]
            }
          ]
        })

      resp =
        endpoint_call.(
          Map.put(
            test_request,
            "dosage_instruction",
            dosage_instruction ++ [dosage_instruction_item]
          )
        )

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.dosage_instruction",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "incorrect additional instruction ($.dosage_instruction.[1].additional_instruction.[1].coding.[1].code)",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]

      # site testing

      dosage_instruction_item =
        dosage_instruction
        |> hd()
        |> Map.put("site", %{
          "coding" => [
            %{
              "system" => "eHealth/SNOMED/anatomical_structure_administration_site_codes",
              "code" => "344001"
            },
            %{
              "system" => "eHealth/SNOMED/anatomical_structure_administration_site_codes",
              "code" => "test"
            }
          ]
        })

      resp = endpoint_call.(Map.put(test_request, "dosage_instruction", [dosage_instruction_item]))

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.dosage_instruction",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "incorrect site ($.dosage_instruction.[0].site.coding.[1].code)",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "failed when started_at less than existing medication request ended_at param", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()

      expect_ops_last_medication_request_dates(%{
        "started_at" => Date.add(Date.utc_today(), -1),
        "ended_at" => Date.utc_today()
      })

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.started_at",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "It can be only 1 active/ completed medication request request or medication request per one innm for the same patient at the same period of time!",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "failed when new mrr created_at parameter conflicts with existing mr: mr dispense period >= mrr_standart_duration",
         %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()

      config = Confex.fetch_env!(:core, :medication_request_request)
      mrr_standard_duration = config[:standard_duration]
      max_mrr_renew_days = config[:max_renew_days]

      current_day = Date.utc_today()
      created_at = current_day
      ended_at = Date.add(current_day, max_mrr_renew_days + 1)
      started_at = Date.add(ended_at, -mrr_standard_duration)

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      expect_ops_last_medication_request_dates(%{
        "started_at" => started_at,
        "ended_at" => ended_at
      })

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id,
          "created_at" => created_at |> Date.to_string(),
          "started_at" => ended_at |> Date.add(1) |> Date.to_string(),
          "ended_at" => ended_at |> Date.add(medication_dispense_period + 1) |> Date.to_string()
        })

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.created_at",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "It's to early to create new medication request for such innm_dosage and medical_program_id",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "success when new mrr created_at parameter does not conflict with existing mr: mr dispense period >= mrr_standart_duration",
         %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()

      current_config = Application.get_env(:core, :medication_request_request)

      on_exit(fn ->
        Application.put_env(:core, :medication_request_request, current_config)
      end)

      Application.put_env(
        :core,
        :medication_request_request,
        expire_in_minutes: current_config[:expire_in_minutes],
        otp_code_length: current_config[:otp_code_length],
        delay_input: current_config[:delay_input],
        min_renew_days: current_config[:min_renew_days],
        standard_duration: 3,
        max_renew_days: 2
      )

      config = Application.get_env(:core, :medication_request_request)
      mrr_standard_duration = config[:standard_duration]
      max_mrr_renew_days = config[:max_renew_days]

      current_day = Date.utc_today()
      created_at = current_day
      ended_at = Date.add(current_day, max_mrr_renew_days)
      started_at = Date.add(ended_at, -mrr_standard_duration)

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      expect_ops_last_medication_request_dates(%{
        "started_at" => started_at,
        "ended_at" => ended_at
      })

      expect_encounter_status("finished")

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id,
          "created_at" => created_at |> Date.to_string(),
          "started_at" => ended_at |> Date.add(1) |> Date.to_string(),
          "ended_at" => ended_at |> Date.add(medication_dispense_period + 1) |> Date.to_string()
        })

      assert conn
             |> post(medication_request_request_path(conn, :create),
               medication_request_request: test_request
             )
             |> json_response(201)
    end

    test "failed when new mrr created_at parameter conflicts with existing mr: mr dispense period < mrr_standart_duration",
         %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()

      config = Confex.fetch_env!(:core, :medication_request_request)
      mrr_standard_duration = config[:standard_duration]
      min_mrr_renew_days = config[:min_renew_days]

      current_day = Date.utc_today()
      created_at = current_day
      ended_at = Date.add(current_day, min_mrr_renew_days + 1)
      started_at = Date.add(ended_at, 1 - mrr_standard_duration)

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      expect_ops_last_medication_request_dates(%{
        "started_at" => started_at,
        "ended_at" => ended_at
      })

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id,
          "created_at" => created_at |> Date.to_string(),
          "started_at" => ended_at |> Date.add(1) |> Date.to_string(),
          "ended_at" => ended_at |> Date.add(medication_dispense_period + 1) |> Date.to_string()
        })

      resp =
        conn
        |> post(medication_request_request_path(conn, :create),
          medication_request_request: test_request
        )
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.created_at",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "It's to early to create new medication request for such innm_dosage and medical_program_id",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "success when new mrr created_at parameter does not conflict with existing mr: mr dispense period < mrr_standart_duration",
         %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()

      current_config = Application.get_env(:core, :medication_request_request)

      on_exit(fn ->
        Application.put_env(:core, :medication_request_request, current_config)
      end)

      Application.put_env(
        :core,
        :medication_request_request,
        expire_in_minutes: current_config[:expire_in_minutes],
        otp_code_length: current_config[:otp_code_length],
        delay_input: current_config[:delay_input],
        max_renew_days: current_config[:max_renew_days],
        standard_duration: 3,
        min_renew_days: 2
      )

      config = Application.get_env(:core, :medication_request_request)
      mrr_standard_duration = config[:standard_duration]
      min_mrr_renew_days = config[:min_renew_days]

      current_day = Date.utc_today()
      created_at = current_day
      ended_at = Date.add(current_day, min_mrr_renew_days)
      started_at = Date.add(ended_at, 1 - mrr_standard_duration)

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      expect_ops_last_medication_request_dates(%{
        "started_at" => started_at,
        "ended_at" => ended_at
      })

      expect_encounter_status("finished")

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id,
          "created_at" => created_at |> Date.to_string(),
          "started_at" => ended_at |> Date.add(1) |> Date.to_string(),
          "ended_at" => ended_at |> Date.add(medication_dispense_period + 1) |> Date.to_string()
        })

      assert conn
             |> post(medication_request_request_path(conn, :create),
               medication_request_request: test_request
             )
             |> json_response(201)
    end

    test "internal error when RPC call OPS returns error", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(:error)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      assert_raise(RpcError, fn ->
        post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)
      end)
    end
  end

  describe "prequalify medication request request" do
    test "works when data is valid", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")
      expect_ops_last_medication_request_dates(nil)

      expect(OPSMock, :get_prequalify_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "intent" => "order"
        })
        |> Map.delete("medical_program_id")

      data = %{medication_request_request: test_request, programs: [%{id: pm.medical_program_id}]}

      schema_path =
        "../core/specs/json_schemas/medication_request_request/medication_request_request_prequalify_response.json"

      resp =
        conn
        |> post(medication_request_request_path(conn, :prequalify), data)
        |> json_response(200)
        |> Map.get("data")
        |> assert_json_schema(schema_path)
        |> Enum.at(0)

      assert %{"status" => "VALID"} = resp
    end

    test "failed on medical programs validation", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")

      {medication_id, pm} = create_medications_structure()

      inactive_mp = insert(:prm, :medical_program, is_active: false)
      inactive_pm = insert(:prm, :program_medication, medical_program_id: inactive_mp.id)

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "intent" => "order"
        })
        |> Map.delete("medical_program_id")

      data = %{
        medication_request_request: test_request,
        programs: [
          %{id: pm.medical_program_id},
          %{id: inactive_pm.medical_program_id},
          %{id: UUID.generate()}
        ]
      }

      resp =
        conn
        |> post(medication_request_request_path(conn, :prequalify), data)
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.programs.[1].id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Medical program is not active",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.programs.[2].id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Medical program not found",
                       "params" => [],
                       "rule" => "required"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "show proper message when program medication is invalid", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")
      expect_ops_last_medication_request_dates(nil)
      {medication_id, _} = create_medications_structure()
      pm1 = insert(:prm, :program_medication)

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "intent" => "order"
        })
        |> Map.delete("medical_program_id")

      resp =
        conn
        |> post(medication_request_request_path(conn, :prequalify), %{
          medication_request_request: test_request,
          programs: [%{id: pm1.medical_program_id}]
        })
        |> json_response(200)
        |> Map.get("data")
        |> hd()

      assert %{
               "status" => "INVALID",
               "rejection_reason" => ~s(Innm not on the list of approved innms for program "Доступні ліки")
             } = resp
    end

    test "render error when data is invalid", %{conn: conn} do
      test_request = test_request(%{"person_id" => ""})

      assert conn
             |> post(medication_request_request_path(conn, :prequalify), %{
               medication_request_request: test_request,
               programs: []
             })
             |> json_response(422)
    end

    test "failed when intent is PLAN", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "intent" => "plan",
          "medication_id" => medication_id
        })
        |> Map.delete("medical_program_id")

      data = %{medication_request_request: test_request, programs: [%{id: pm.medical_program_id}]}

      resp =
        conn
        |> post(medication_request_request_path(conn, :prequalify), data)
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Plan can't be qualified"
    end

    test "render medication_request_request when optional fields are absent", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)

      expect(OPSMock, :get_prequalify_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "intent" => "order"
        })
        |> Map.drop(~w(medical_program_id context dosage_instruction))

      data = %{medication_request_request: test_request, programs: [%{id: pm.medical_program_id}]}

      assert conn
             |> post(medication_request_request_path(conn, :prequalify), data)
             |> json_response(200)
    end

    test "failed when new mrr created_at parameter conflicts with existing mr: mr dispense period >= mrr_standart_duration",
         %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")

      config = Confex.fetch_env!(:core, :medication_request_request)
      mrr_standard_duration = config[:standard_duration]
      max_mrr_renew_days = config[:max_renew_days]

      current_day = Date.utc_today()
      created_at = current_day
      ended_at = Date.add(current_day, max_mrr_renew_days + 1)
      started_at = Date.add(ended_at, -mrr_standard_duration)

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      expect_ops_last_medication_request_dates(%{
        "started_at" => started_at,
        "ended_at" => ended_at
      })

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "created_at" => created_at |> Date.to_string(),
          "started_at" => ended_at |> Date.add(1) |> Date.to_string(),
          "ended_at" => ended_at |> Date.add(medication_dispense_period + 1) |> Date.to_string()
        })
        |> Map.delete("medical_program_id")

      data = %{medication_request_request: test_request, programs: [%{id: pm.medical_program_id}]}

      resp =
        conn
        |> post(medication_request_request_path(conn, :prequalify), data)
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.programs.[0].id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "It's to early to create new medication request for such innm_dosage and medical_program_id",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "success when new mrr created_at parameter does not conflict with existing mr: mr dispense period => mrr_standart_duration",
         %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")

      current_config = Application.get_env(:core, :medication_request_request)

      on_exit(fn ->
        Application.put_env(:core, :medication_request_request, current_config)
      end)

      Application.put_env(
        :core,
        :medication_request_request,
        expire_in_minutes: current_config[:expire_in_minutes],
        otp_code_length: current_config[:otp_code_length],
        delay_input: current_config[:delay_input],
        min_renew_days: current_config[:min_renew_days],
        standard_duration: 3,
        max_renew_days: 2
      )

      config = Application.get_env(:core, :medication_request_request)
      mrr_standard_duration = config[:standard_duration]
      max_mrr_renew_days = config[:max_renew_days]

      current_day = Date.utc_today()
      created_at = current_day
      ended_at = Date.add(current_day, max_mrr_renew_days)
      started_at = Date.add(ended_at, -mrr_standard_duration)

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      expect_ops_last_medication_request_dates(%{
        "started_at" => started_at,
        "ended_at" => ended_at
      })

      expect(OPSMock, :get_prequalify_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "created_at" => created_at |> Date.to_string(),
          "started_at" => created_at |> Date.to_string(),
          "ended_at" => created_at |> Date.add(medication_dispense_period) |> Date.to_string()
        })
        |> Map.delete("medical_program_id")

      data = %{medication_request_request: test_request, programs: [%{id: pm.medical_program_id}]}

      schema_path =
        "../core/specs/json_schemas/medication_request_request/medication_request_request_prequalify_response.json"

      resp =
        conn
        |> post(medication_request_request_path(conn, :prequalify), data)
        |> json_response(200)
        |> Map.get("data")
        |> assert_json_schema(schema_path)
        |> Enum.at(0)

      assert %{"status" => "VALID"} = resp
    end

    test "failed when new mrr created_at parameter conflicts with existing mr: mr dispense period < mrr_standart_duration",
         %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")

      config = Confex.fetch_env!(:core, :medication_request_request)
      mrr_standard_duration = config[:standard_duration]
      min_mrr_renew_days = config[:min_renew_days]

      current_day = Date.utc_today()
      created_at = current_day
      ended_at = Date.add(current_day, min_mrr_renew_days + 1)
      started_at = Date.add(ended_at, 1 - mrr_standard_duration)

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      expect_ops_last_medication_request_dates(%{
        "started_at" => started_at,
        "ended_at" => ended_at
      })

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "created_at" => created_at |> Date.to_string(),
          "started_at" => ended_at |> Date.add(1) |> Date.to_string(),
          "ended_at" => ended_at |> Date.add(medication_dispense_period + 1) |> Date.to_string()
        })
        |> Map.delete("medical_program_id")

      data = %{medication_request_request: test_request, programs: [%{id: pm.medical_program_id}]}

      resp =
        conn
        |> post(medication_request_request_path(conn, :prequalify), data)
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.programs.[0].id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "It's to early to create new medication request for such innm_dosage and medical_program_id",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "success when new mrr created_at parameter does not conflict with existing mr: mr dispense period < mrr_standart_duration",
         %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_encounter_status("finished")

      current_config = Application.get_env(:core, :medication_request_request)

      on_exit(fn ->
        Application.put_env(:core, :medication_request_request, current_config)
      end)

      Application.put_env(
        :core,
        :medication_request_request,
        expire_in_minutes: current_config[:expire_in_minutes],
        otp_code_length: current_config[:otp_code_length],
        delay_input: current_config[:delay_input],
        max_renew_days: current_config[:max_renew_days],
        standard_duration: 3,
        min_renew_days: 2
      )

      config = Application.get_env(:core, :medication_request_request)
      mrr_standard_duration = config[:standard_duration]
      min_mrr_renew_days = config[:min_renew_days]

      current_day = Date.utc_today()
      created_at = current_day
      ended_at = Date.add(current_day, min_mrr_renew_days)
      started_at = Date.add(ended_at, 1 - mrr_standard_duration)

      medication_dispense_period =
        GlobalParameters.get_values()
        |> Map.get("medication_dispense_period")
        |> String.to_integer()

      expect_ops_last_medication_request_dates(%{
        "started_at" => started_at,
        "ended_at" => ended_at
      })

      expect(OPSMock, :get_prequalify_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "created_at" => created_at |> Date.to_string(),
          "started_at" => created_at |> Date.to_string(),
          "ended_at" => created_at |> Date.add(medication_dispense_period) |> Date.to_string()
        })
        |> Map.delete("medical_program_id")

      data = %{medication_request_request: test_request, programs: [%{id: pm.medical_program_id}]}

      schema_path =
        "../core/specs/json_schemas/medication_request_request/medication_request_request_prequalify_response.json"

      resp =
        conn
        |> post(medication_request_request_path(conn, :prequalify), data)
        |> json_response(200)
        |> Map.get("data")
        |> assert_json_schema(schema_path)
        |> Enum.at(0)

      assert %{"status" => "VALID"} = resp
    end
  end

  describe "reject medication request request" do
    test "works when data is valid", %{conn: conn} do
      expect_mpi_get_person()
      expect_ops_get_declarations()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect_mpi_get_person()

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      conn1 = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert %{"id" => id} = json_response(conn1, 201)["data"]

      conn2 = patch(conn, medication_request_request_path(conn, :reject, id))
      assert %{"id" => id1} = json_response(conn2, 200)["data"]
      assert id == id1

      conn3 = patch(conn, medication_request_request_path(conn, :reject, id))
      assert json_response(conn3, 409)
    end

    test "works when data is invalid", %{conn: conn} do
      conn1 = patch(conn, medication_request_request_path(conn, :reject, Ecto.UUID.generate()))
      assert json_response(conn1, 404)
    end
  end

  describe "autotermination works fine" do
    test "with direct call", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      conn1 = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert %{"id" => id} = json_response(conn1, 201)["data"]

      Repo.update_all(Core.MedicationRequestRequest,
        set: [inserted_at: ~N[1970-01-01 13:26:08.003]]
      )

      MedicationRequestRequests.autoterminate()
      mrr = MedicationRequestRequests.get_medication_request_request(id)
      assert mrr.status == "EXPIRED"
      assert mrr.updated_by == Confex.fetch_env!(:core, :system_user)
    end
  end

  describe "sign medication request request" do
    test "when data is valid", %{conn: conn} do
      person = build(:person)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_ops_last_medication_request_dates(nil)
      expect_ops_get_declarations()
      expect_encounter_status("finished")

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)

      expect(OPSMock, :create_medication_request, fn params, _headers ->
        medication_request =
          :medication_request
          |> build(id: params.medication_request.id)
          |> Jason.encode!()
          |> Jason.decode!()

        {:ok, %{"data" => medication_request}}
      end)

      expect_encounter_status("finished")
      expect_otp_verification_send_sms()

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      conn1 = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert mrr = json_response(conn1, 201)["data"]

      signed_mrr =
        mrr
        |> Jason.encode!()
        |> Base.encode64()

      drfo =
        mrr
        |> get_in(["employee", "party", "id"])
        |> (fn x -> Core.PRMRepo.get!(Core.Parties.Party, x) end).()
        |> Map.get(:tax_id)

      drfo_signed_content(mrr, drfo)
      conn = Plug.Conn.put_req_header(conn, "drfo", drfo)

      conn1 =
        patch(conn, medication_request_request_path(conn, :sign, mrr["id"]), %{
          signed_medication_request_request: signed_mrr,
          signed_content_encoding: "base64"
        })

      assert json_response(conn1, 200)
      assert json_response(conn1, 200)["data"]["status"] == "ACTIVE"
    end

    test "when data is valid (medical_program param is optional)", %{conn: conn} do
      person = build(:person)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)

      expect_ops_get_declarations()
      expect_encounter_status("finished")
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_encounter_status("finished")
      expect_otp_verification_send_sms()

      expect(OPSMock, :create_medication_request, fn params, _headers ->
        medication_request = build(:medication_request, id: params.medication_request.id)

        medication_request =
          medication_request
          |> Jason.encode!()
          |> Jason.decode!()

        {:ok, %{"data" => medication_request}}
      end)

      {medication_id, _} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "intent" => "order"
        })
        |> Map.delete("medical_program_id")

      conn1 = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert mrr = json_response(conn1, 201)["data"]

      signed_mrr =
        mrr
        |> Jason.encode!()
        |> Base.encode64()

      drfo =
        mrr
        |> get_in(["employee", "party", "id"])
        |> (fn x -> Core.PRMRepo.get!(Core.Parties.Party, x) end).()
        |> Map.get(:tax_id)

      drfo_signed_content(mrr, drfo)
      conn = Plug.Conn.put_req_header(conn, "drfo", drfo)

      conn1 =
        patch(conn, medication_request_request_path(conn, :sign, mrr["id"]), %{
          signed_medication_request_request: signed_mrr,
          signed_content_encoding: "base64"
        })

      assert json_response(conn1, 200)
      assert json_response(conn1, 200)["data"]["status"] == "ACTIVE"
    end

    test "return 404 if request not found", %{conn: conn} do
      conn1 =
        patch(conn, medication_request_request_path(conn, :sign, Ecto.UUID.generate()), %{
          signed_medication_request_request: "",
          signed_content_encoding: "base64"
        })

      assert json_response(conn1, 404)
    end

    test "return 409 if request status is not new", %{conn: conn} do
      expect_ops_get_declarations()
      expect_mpi_get_person()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      conn1 = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert mrr = json_response(conn1, 201)["data"]
      Repo.update_all(Core.MedicationRequestRequest, set: [status: "EXPIRED"])

      conn1 =
        patch(conn, medication_request_request_path(conn, :sign, mrr["id"]), %{
          signed_medication_request_request: "",
          signed_content_encoding: "base64"
        })

      assert json_response(conn1, 409)
    end

    test "return 422 if request is not valid", %{conn: conn} do
      conn1 =
        patch(conn, medication_request_request_path(conn, :sign, Ecto.UUID.generate()), %{
          signed_medication_request_request: %{},
          signed_content_encoding: "base64"
        })

      assert json_response(conn1, 422)
    end

    test "return 422 if signature is not valid", %{conn: conn} do
      person = build(:person)
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_ops_get_declarations()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_encounter_status("finished")

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      conn1 = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert mrr = json_response(conn1, 201)["data"]

      signed_mrr =
        mrr
        |> Jason.encode!()
        |> Base.encode64()

      drfo =
        mrr
        |> get_in(["employee", "party", "id"])
        |> (fn x -> Core.PRMRepo.get!(Core.Parties.Party, x) end).()
        |> Map.get(:tax_id)

      expect(SignatureMock, :decode_and_validate, fn _, _ ->
        {:error, {:bad_request, "Invalid signature"}}
      end)

      resp =
        conn
        |> Plug.Conn.put_req_header("drfo", drfo)
        |> patch(medication_request_request_path(conn, :sign, mrr["id"]), %{
          signed_medication_request_request: signed_mrr,
          signed_content_encoding: "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.signed_medication_request_request",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Invalid signature",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "when some data is invalid", %{conn: conn} do
      person = build(:person)
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_ops_get_declarations()
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_encounter_status("finished")
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      conn1 = post(conn, medication_request_request_path(conn, :create), medication_request_request: test_request)

      assert mrr = json_response(conn1, 201)["data"]
      signed_mrr = put_in(mrr, ["employee", "id"], Ecto.UUID.generate())
      drfo_signed_content(signed_mrr, nil)

      conn1 =
        patch(conn, medication_request_request_path(conn, :sign, mrr["id"]), %{
          signed_medication_request_request:
            signed_mrr
            |> Jason.encode!()
            |> Base.encode64(),
          signed_content_encoding: "base64"
        })

      assert json_response(conn1, 422)
    end

    test "when context in signed context is invalid", %{conn: conn} do
      person = build(:person)
      expect_ops_get_declarations()
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      mrr =
        conn
        |> post(medication_request_request_path(conn, :create), medication_request_request: test_request)
        |> json_response(201)
        |> Map.get("data")

      signed_mrr =
        mrr
        |> Jason.encode!()
        |> Base.encode64()

      expect_encounter_status("entered_in_error")

      resp =
        conn
        |> patch(medication_request_request_path(conn, :sign, mrr["id"]), %{
          signed_medication_request_request:
            signed_mrr
            |> Jason.encode!()
            |> Base.encode64(),
          signed_content_encoding: "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.context",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Entity in status \"entered-in-error\" can not be referenced",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "when request emploee_id.drfo is invalid", %{conn: conn} do
      person = build(:person)

      expect_ops_get_declarations()
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_ops_last_medication_request_dates(nil)
      expect_encounter_status("finished")
      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] -> {:ok, person} end)
      expect_encounter_status("finished")

      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request(%{
          "medication_id" => medication_id,
          "medical_program_id" => pm.medical_program_id
        })

      assert mrr =
               conn
               |> post(medication_request_request_path(conn, :create), medication_request_request: test_request)
               |> json_response(201)
               |> Map.get("data")

      signed_mrr =
        mrr
        |> Jason.encode!()
        |> Base.encode64()

      drfo =
        mrr
        |> get_in(["employee", "party", "id"])
        |> (fn x -> Core.PRMRepo.get!(Core.Parties.Party, x) end).()
        |> Map.get(:tax_id)

      drfo_signed_content(mrr, "TEST")

      resp =
        conn
        |> Plug.Conn.put_req_header("drfo", drfo)
        |> patch(medication_request_request_path(conn, :sign, mrr["id"]), %{
          signed_medication_request_request: signed_mrr,
          signed_content_encoding: "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.employee_id.drfo",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Does not match the signer drfo",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end
  end

  defp expect_ops_get_declarations(times_called \\ 1) do
    expect(OPSMock, :get_declarations, times_called, fn _params, _headers ->
      declaration = build(:declaration)

      {:ok, MockServer.wrap_response_with_paging([declaration])}
    end)
  end

  defp expect_mpi_get_person(times_called \\ 1) do
    expect(RPCWorkerMock, :run, times_called, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
      {:ok, build(:person, id: id)}
    end)
  end

  defp create_medications_structure do
    %{id: innm_id} = insert(:prm, :innm, name: "Будафинол")
    %{id: dosage_id} = insert(:prm, :innm_dosage, name: "Будафинолон Альтернативний")
    %{id: dosage_id2} = insert(:prm, :innm_dosage, name: "Будафинолон Альтернативний 2")

    %{id: med_id} = insert(:prm, :medication, package_qty: 10, package_min_qty: 5, name: "Будафинолодон")

    %{id: med_id2} = insert(:prm, :medication, package_qty: 10, package_min_qty: 5, name: "Будафинолодон2")

    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id, innm_child_id: innm_id)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id2, innm_child_id: innm_id)
    insert(:prm, :ingredient_medication, parent_id: med_id, medication_child_id: dosage_id)
    insert(:prm, :ingredient_medication, parent_id: med_id2, medication_child_id: dosage_id2)

    pm = insert(:prm, :program_medication, medication_id: med_id)

    insert(:prm, :program_medication,
      medication_id: med_id2,
      medical_program_id: pm.medical_program_id
    )

    {dosage_id, pm}
  end

  defp test_request(params) do
    medication_dispense_period =
      GlobalParameters.get_values()
      |> Map.get("medication_dispense_period")
      |> String.to_integer()

    day = Date.utc_today()

    "../core/test/data/medication_request_request/medication_request_request.json"
    |> File.read!()
    |> Jason.decode!()
    |> Map.merge(%{
      "created_at" => day |> Date.to_string(),
      "started_at" => day |> Date.to_string(),
      "ended_at" => day |> Date.add(medication_dispense_period) |> Date.to_string()
    })
    |> Map.merge(params)
  end

  defp filter_authentication_method(nil), do: %{}

  defp filter_authentication_method(%{"phone_number" => number} = method) do
    Map.put(method, "phone_number", Phone.hide_number(number))
  end

  defp filter_authentication_method(method), do: method
end
