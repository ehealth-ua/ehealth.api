defmodule EHealth.Web.MedicationRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Mox

  alias Core.LegalEntities.LegalEntity
  alias Core.MedicationRequests.MedicationRequest
  alias Core.PRMRepo
  alias Core.Utils.NumberGenerator
  alias Ecto.UUID

  setup :verify_on_exit!

  setup %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    {:ok, conn: put_client_id_header(conn, id)}
  end

  describe "list medication requests" do
    test "success list medication requests with different intents", %{conn: conn} do
      msp()

      expect(RPCWorkerMock, :run, 2, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id)}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      person_id = Ecto.UUID.generate()

      medication_request_order =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          person_id: person_id,
          intent: MedicationRequest.intent(:order),
          status: "COMPLETED",
          rejected_at: DateTime.utc_now(),
          rejected_by: UUID.generate(),
          reject_reason: "TEST"
        })

      medication_request_plan =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id,
          person_id: person_id,
          intent: MedicationRequest.intent(:plan),
          status: "COMPLETED"
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request_order, medication_request_plan],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 2,
             "total_pages" => 1
           }
         }}
      end)

      conn =
        get(conn, medication_request_path(conn, :index, %{"page_size" => 2}), %{
          "employee_id" => employee_id,
          "person_id" => person_id
        })

      resp = json_response(conn, 200)
      assert 2 == length(resp["data"])
      assert_list_response_schema(resp, "medication_request")

      rejected_fields = ~w(rejected_at rejected_by reject_reason)

      Enum.each(rejected_fields, fn rejected_field ->
        assert Map.has_key?(Enum.at(resp["data"], 0), rejected_field)
      end)

      Enum.each(rejected_fields, fn rejected_field ->
        refute Map.has_key?(Enum.at(resp["data"], 1), rejected_field)
      end)
    end

    test "success list medication requests with different intents without medical_program_id", %{conn: conn} do
      msp()

      expect(RPCWorkerMock, :run, 2, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id)}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      person_id = Ecto.UUID.generate()

      medication_request_order =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id,
          person_id: person_id,
          intent: MedicationRequest.intent(:order),
          status: "COMPLETED",
          rejected_at: DateTime.utc_now(),
          rejected_by: UUID.generate(),
          reject_reason: "TEST"
        })

      medication_request_plan =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id,
          person_id: person_id,
          intent: MedicationRequest.intent(:plan),
          status: "COMPLETED"
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request_order, medication_request_plan],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 2,
             "total_pages" => 1
           }
         }}
      end)

      conn =
        get(conn, medication_request_path(conn, :index, %{"page_size" => 2}), %{
          "employee_id" => employee_id,
          "person_id" => person_id
        })

      resp = json_response(conn, 200)
      assert 2 == length(resp["data"])
      assert_list_response_schema(resp, "medication_request")
    end

    test "could not load remote reference", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request = build_resp(%{legal_entity_id: legal_entity_id})

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn = get(conn, medication_request_path(conn, :index))
      assert json_response(conn, 500)
    end
  end

  describe "show medication_request" do
    test "success get medication_request by id (both ORDER and PLAN)", %{conn: conn} do
      msp(2)

      expect(RPCWorkerMock, :run, 2, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id)}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn
      |> get(medication_request_path(conn, :show, medication_request["id"]))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("medication_request")

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [
             medication_request
             |> Map.delete("medical_program_id")
             |> Map.merge(%{
               "intent" => MedicationRequest.intent(:plan),
               "rejected_at" => DateTime.utc_now(),
               "rejected_by" => UUID.generate(),
               "reject_reason" => "TEST"
             })
           ],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      resp =
        conn
        |> get(medication_request_path(conn, :show, medication_request["id"]))
        |> json_response(200)
        |> Map.get("data")

      assert_show_response_schema(resp, "medication_request")

      rejected_fields = ~w(rejected_at rejected_by reject_reason)

      Enum.each(rejected_fields, fn rejected_field ->
        assert Map.has_key?(resp, rejected_field)
      end)
    end

    test "success get medication_request by id without medical_program_id (medical_program_id param is optional)", %{
      conn: conn
    } do
      msp()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok,
         build(:person, id: id, first_name: "Шах    Хож-Ахмед", last_name: "Аль-Бекиров", second_name: "Саид- заурович")}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id,
          intent: MedicationRequest.intent(:order)
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      resp =
        conn
        |> get(medication_request_path(conn, :show, medication_request["id"]))
        |> json_response(200)
        |> Map.get("data")

      assert_show_response_schema(resp, "medication_request")
      assert "Аль-Бекиров Ш.-Х.-А. С.-З." == get_in(resp, ~w(person short_name))
    end

    test "failed when medical program is invalid", %{conn: conn} do
      msp()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id)}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: UUID.generate(),
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      resp =
        conn
        |> get(medication_request_path(conn, :show, medication_request["id"]))
        |> json_response(500)

      assert get_in(resp, ~w(error message)) =~ "Could not load remote reference for medication_request"
    end

    test "not found", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      insert(:prm, :party_user, user_id: user_id)

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
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

      conn = get(conn, medication_request_path(conn, :show, UUID.generate()))
      assert json_response(conn, 404)
    end
  end

  describe "show medication_request by number" do
    test "success get medication_request by number", %{conn: conn} do
      msp()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id)}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request_number = NumberGenerator.generate(0)

      medication_request =
        %{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        }
        |> build_resp()
        |> Map.put("request_number", medication_request_number)

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn
      |> get(medication_request_path(conn, :show, medication_request_number))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("medication_request")
    end

    test "not found", %{conn: conn} do
      msp()

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
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

      conn = get(conn, medication_request_path(conn, :show, NumberGenerator.generate(0)))
      assert json_response(conn, 404)
    end
  end

  describe "qualify medication request" do
    test "success qualify", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn =
        post(conn, medication_request_path(conn, :qualify, medication_request["id"]), %{
          "programs" => [%{"id" => medical_program_id}]
        })

      resp = json_response(conn, 200)

      schema =
        "../core/specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "success qualify without medical_program_id (medical_program_id param is optional)", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn =
        post(conn, medication_request_path(conn, :qualify, medication_request["id"]), %{
          "programs" => [%{"id" => medical_program_id}]
        })

      resp = json_response(conn, 200)

      schema =
        "../core/specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "success qualify as admin", %{conn: conn} do
      admin()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: medical_program_id} = insert(:prm, :medical_program)
      %{id: innm_dosage_id} = insert_innm_dosage()
      %{medication_id: medication_id} = insert(:prm, :program_medication, medical_program_id: medical_program_id)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      insert(
        :prm,
        :ingredient_medication,
        parent_id: medication_id,
        medication_child_id: innm_dosage_id
      )

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :get_qualify_medication_requests, fn _params, _headers ->
        {:ok, %{"data" => [medication_id]}}
      end)

      conn = put_client_id_header(conn, UUID.generate())

      conn =
        post(conn, medication_request_path(conn, :qualify, medication_request["id"]), %{
          "programs" => [%{"id" => medical_program_id}]
        })

      resp = json_response(conn, 200)

      schema =
        "../core/specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "INVALID qualify as admin", %{conn: conn} do
      admin()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn = put_client_id_header(conn, UUID.generate())

      conn =
        post(conn, medication_request_path(conn, :qualify, medication_request["id"]), %{
          "programs" => [%{"id" => medical_program_id}]
        })

      resp = json_response(conn, 200)

      schema =
        "../core/specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "failed validation", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn = post(conn, medication_request_path(conn, :qualify, UUID.generate()))
      resp = json_response(conn, 422)

      assert %{"error" => %{"invalid" => [%{"entry" => "$.programs"}]}} = resp
    end

    test "medication_request not found", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      insert(:prm, :party_user, user_id: user_id)

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
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

      conn = post(conn, medication_request_path(conn, :qualify, UUID.generate()))
      assert json_response(conn, 404)
    end

    test "program medication not found", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn =
        post(conn, medication_request_path(conn, :qualify, medication_request["id"]), %{
          "programs" => [%{"id" => Ecto.UUID.generate()}, %{"id" => Ecto.UUID.generate()}]
        })

      resp = json_response(conn, 422)
      assert 2 == Enum.count(resp["error"]["invalid"])
    end

    test "failed when intent is PLAN", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id,
          intent: MedicationRequest.intent(:plan)
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      resp =
        conn
        |> post(medication_request_path(conn, :qualify, medication_request["id"]), %{
          "programs" => [%{"id" => UUID.generate()}]
        })
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Medication request with type (intent) PLAN cannot be qualified"
    end
  end

  describe "reject medication request" do
    test "success ORDER", %{conn: conn} do
      msp(2)
      person = build(:person)

      expect(RPCWorkerMock, :run, 2, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] ->
        {:ok, person}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :update_medication_request, fn _id, %{"medication_request" => params}, _headers ->
        {:ok, %{"data" => Map.merge(medication_request, params)}}
      end)

      expect(OTPVerificationMock, :send_sms, fn %{phone_number: phone_number, body: body, type: type}, _ ->
        {:ok, %{"data" => %{"body" => body, "phone_number" => phone_number, "type" => type}}}
      end)

      reject_reason = "TEST"

      content =
        conn
        |> get(medication_request_path(conn, :show, medication_request["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.put("reject_reason", reject_reason)

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

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      resp =
        conn
        |> patch(medication_request_path(conn, :reject, medication_request["id"]), %{
          "signed_medication_reject" =>
            content
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(200)
        |> Map.get("data")
        |> assert_show_response_schema("medication_request")

      assert "REJECTED" == resp["status"]
      assert reject_reason == resp["reject_reason"]
    end

    test "success ORDER without medical_program_id (medical_program_id param is optional)", %{conn: conn} do
      msp(2)
      person = build(:person)

      expect(RPCWorkerMock, :run, 2, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] ->
        {:ok, person}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :update_medication_request, fn _id, %{"medication_request" => params}, _headers ->
        {:ok, %{"data" => Map.merge(medication_request, params)}}
      end)

      expect(OTPVerificationMock, :send_sms, fn %{phone_number: phone_number, body: body, type: type}, _ ->
        {:ok, %{"data" => %{"body" => body, "phone_number" => phone_number, "type" => type}}}
      end)

      reject_reason = "TEST"

      content =
        conn
        |> get(medication_request_path(conn, :show, medication_request["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.put("reject_reason", reject_reason)

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

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      resp =
        conn
        |> patch(medication_request_path(conn, :reject, medication_request["id"]), %{
          "signed_medication_reject" =>
            content
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(200)
        |> Map.get("data")
        |> assert_show_response_schema("medication_request")

      assert "REJECTED" == resp["status"]
      assert reject_reason == resp["reject_reason"]
    end

    test "success PLAN", %{conn: conn} do
      msp(2)
      person = build(:person)

      expect(RPCWorkerMock, :run, 2, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] ->
        {:ok, person}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)

      medication_request =
        %{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id,
          intent: MedicationRequest.intent(:plan)
        }
        |> build_resp()
        |> Map.drop(~w(dispense_valid_from dispense_valid_to))

      expect(OPSMock, :get_doctor_medication_requests, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :update_medication_request, fn _id, %{"medication_request" => params}, _headers ->
        {:ok, %{"data" => Map.merge(medication_request, params)}}
      end)

      expect(OTPVerificationMock, :send_sms, fn %{phone_number: phone_number, body: body, type: type}, _ ->
        {:ok, %{"data" => %{"body" => body, "phone_number" => phone_number, "type" => type}}}
      end)

      reject_reason = "TEST"

      content =
        conn
        |> get(medication_request_path(conn, :show, medication_request["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.put("reject_reason", reject_reason)

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

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      resp =
        conn
        |> patch(medication_request_path(conn, :reject, medication_request["id"]), %{
          "signed_medication_reject" =>
            content
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(200)
        |> Map.get("data")
        |> assert_show_response_schema("medication_request")

      assert "REJECTED" == resp["status"]
      assert reject_reason == resp["reject_reason"]
    end

    test "fail to find medication request", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
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

      assert conn
             |> patch(medication_request_path(conn, :reject, UUID.generate()), %{
               "signed_medication_reject" =>
                 %{}
                 |> Jason.encode!()
                 |> Base.encode64(),
               "signed_content_encoding" => "base64"
             })
             |> json_response(404)
    end

    test "invalid transition", %{conn: conn} do
      msp()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id)}
      end)

      user_id = get_consumer_id(conn.req_headers)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity_id = get_client_id(conn.req_headers)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      division = insert(:prm, :division)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          status: "COMPLETED"
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 0,
             "total_pages" => 1
           }
         }}
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
        |> patch(medication_request_path(conn, :reject, medication_request["id"]), %{
          "signed_medication_reject" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Invalid status Request for Medication request for reject transition!"
    end

    test "medication request has medication dispenses with status NEW, PROCESSED etc", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id)}
      end)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity_id = get_client_id(conn.req_headers)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      division = insert(:prm, :division)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      medication_dispense = build(:medication_dispense, medication_request_id: medication_request["id"], status: "NEW")

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 0,
             "total_pages" => 1
           }
         }}
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
        |> patch(medication_request_path(conn, :reject, medication_request["id"]), %{
          "signed_medication_reject" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(409)

      assert get_in(resp, ~w(error message)) ==
               "Medication request with connected processed medication dispenses can not be rejected"
    end

    test "invalid user drfo in DS", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

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
        |> patch(medication_request_path(conn, :reject, UUID.generate()), %{
          "signed_medication_reject" =>
            %{}
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{"message" => "Does not match the signer drfo"} = resp["error"]
    end

    test "invalid request params", %{conn: conn} do
      msp()

      resp =
        conn
        |> patch(medication_request_path(conn, :reject, UUID.generate()), %{"test" => "test"})
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.signed_medication_reject",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "required property signed_medication_reject was not present",
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

    test "invalid content params", %{conn: conn} do
      msp(2)
      person = build(:person)

      expect(RPCWorkerMock, :run, 2, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] ->
        {:ok, person}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
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
        |> get(medication_request_path(conn, :show, medication_request["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.merge(%{
          "reject_reason" => 12345,
          "test" => "test"
        })
        |> Map.delete("id")

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
        |> patch(medication_request_path(conn, :reject, medication_request["id"]), %{
          "signed_medication_reject" =>
            content
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.reject_reason",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "type mismatch. Expected string but got integer",
                       "rule" => "cast"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.test",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "schema does not allow additional properties",
                       "rule" => "schema"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "required property id was not present",
                       "rule" => "required"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "failed when signed content does not match the previously created content", %{conn: conn} do
      msp(2)
      person = build(:person)

      expect(RPCWorkerMock, :run, 2, fn "mpi", MPI.Rpc, :get_person_by_id, [_id] ->
        {:ok, person}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      party_user =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OPSMock, :get_doctor_medication_requests, 2, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      expect(OPSMock, :get_medication_dispenses, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
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
        |> get(medication_request_path(conn, :show, medication_request["id"]))
        |> json_response(200)
        |> Map.get("data")
        |> Map.merge(%{
          "reject_reason" => "TEST",
          "id" => UUID.generate()
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
        |> patch(medication_request_path(conn, :reject, medication_request["id"]), %{
          "signed_medication_reject" =>
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

  describe "resend medication request info" do
    test "success", %{conn: conn} do
      msp()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id)}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id
        })

      expect(OTPVerificationMock, :send_sms, fn %{phone_number: phone_number, body: body, type: type}, _ ->
        {:ok, %{"data" => %{"body" => body, "phone_number" => phone_number, "type" => type}}}
      end)

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      conn = patch(conn, medication_request_path(conn, :resend, medication_request["id"]))
      assert json_response(conn, 200)
    end

    test "404", %{conn: conn} do
      msp()
      user_id = get_consumer_id(conn.req_headers)

      :prm
      |> insert(:party_user, user_id: user_id)
      |> PRMRepo.preload(:party)

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
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

      conn = patch(conn, medication_request_path(conn, :resend, UUID.generate()))
      assert json_response(conn, 404)
    end

    test "failed when intent is PLAN", %{conn: conn} do
      msp()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id)}
      end)

      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      division = insert(:prm, :division)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: nil,
          medication_id: innm_dosage_id,
          intent: MedicationRequest.intent(:plan)
        })

      expect(OPSMock, :get_doctor_medication_requests, fn _params, _headers ->
        {:ok,
         %{
           "data" => [medication_request],
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 1,
             "total_pages" => 1
           }
         }}
      end)

      resp =
        conn
        |> patch(medication_request_path(conn, :resend, medication_request["id"]))
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "For medication request plan information cannot be resent"
    end
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

  defp build_resp(params) do
    medication_request = build(:medication_request, params)

    medication_request
    |> Jason.encode!()
    |> Jason.decode!()
  end
end
