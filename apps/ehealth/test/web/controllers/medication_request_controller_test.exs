defmodule EHealth.Web.MedicationRequestControllerTest do
  use EHealth.Web.ConnCase, async: true
  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Mox

  alias EHealth.PRMRepo
  alias EHealth.LegalEntities.LegalEntity
  alias Ecto.UUID

  setup :verify_on_exit!

  setup %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    {:ok, conn: put_client_id_header(conn, id)}
  end

  describe "list medication requests" do
    test "success list medication requests", %{conn: conn} do
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

      medication_request =
        build_resp(%{
          legal_entity_id: legal_entity_id,
          division_id: division.id,
          employee_id: employee_id,
          medical_program_id: medical_program_id,
          medication_id: innm_dosage_id,
          person_id: person_id,
          status: "COMPLETED"
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
        get(conn, medication_request_path(conn, :index, %{"page_size" => 1}), %{
          "employee_id" => employee_id,
          "person_id" => person_id
        })

      resp = json_response(conn, 200)
      assert 1 == length(resp["data"])
      assert_list_response_schema(resp, "medication_request")
    end

    test "no party user", %{conn: conn} do
      conn = get(conn, medication_request_path(conn, :index))
      assert json_response(conn, 500)
    end

    test "no employees found", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)

      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      insert(:prm, :employee, party: party, legal_entity: legal_entity)
      conn = get(conn, medication_request_path(conn, :index), %{"employee_id" => Ecto.UUID.generate()})
      assert json_response(conn, 403)
    end

    test "could not load remote reference", %{conn: conn} do
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
    test "success get medication_request by id", %{conn: conn} do
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
    end

    test "no party user", %{conn: conn} do
      conn = get(conn, medication_request_path(conn, :show, Ecto.UUID.generate()))
      assert json_response(conn, 500)
    end

    test "not found", %{conn: conn} do
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

  describe "qualify medication request" do
    test "success qualify", %{conn: conn} do
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
        "specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "success qualify as admin", %{conn: conn} do
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

      conn
      |> put_client_id_header(legal_entity_id)
      |> assign(:client_type, "NHS ADMIN")

      conn =
        post(conn, medication_request_path(conn, :qualify, medication_request["id"]), %{
          "programs" => [%{"id" => medical_program_id}]
        })

      resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "INVALID qualify as admin", %{conn: conn} do
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
      |> put_client_id_header(legal_entity_id)
      |> assign(:client_type, "NHS ADMIN")

      conn =
        post(conn, medication_request_path(conn, :qualify, medication_request["id"]), %{
          "programs" => [%{"id" => medical_program_id}]
        })

      resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "failed validation", %{conn: conn} do
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
  end

  describe "reject medication request" do
    test "success", %{conn: conn} do
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

      expect(OPSMock, :update_medication_request, fn _id, _params, _headers ->
        {:ok, %{"data" => medication_request}}
      end)

      expect(OTPVerificationMock, :send_sms, fn phone_number, body, type, _ ->
        {:ok, %{"data" => %{"body" => body, "phone_number" => phone_number, "type" => type}}}
      end)

      conn = patch(conn, medication_request_path(conn, :reject, medication_request["id"]), %{reject_reason: "TEST"})

      assert json_response(conn, 200)
    end

    test "404", %{conn: conn} do
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

      conn = patch(conn, medication_request_path(conn, :reject, UUID.generate()), %{reject_reason: "TEST"})

      assert json_response(conn, 404)
    end
  end

  describe "resend medication request info" do
    test "success", %{conn: conn} do
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

      expect(OTPVerificationMock, :send_sms, fn phone_number, body, type, _ ->
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
    |> Poison.encode!()
    |> Poison.decode!()
  end
end
