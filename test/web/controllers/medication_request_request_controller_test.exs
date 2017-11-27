defmodule EHealth.Web.MedicationRequestRequestControllerTest do
  use EHealth.Web.ConnCase, async: false

  alias EHealth.MedicationRequestRequests

  @legal_entity_id "7cc91a5d-c02f-41e9-b571-1ea4f2375552"

  def fixture(:medication_request_request) do
    {medication_id, pm} = create_medications_structure()
    test_request =
      test_request()
      |> Map.put("medication_id", medication_id)
      |> Map.put("medical_program_id", pm.medical_program_id)
    {:ok, medication_request_request} = MedicationRequestRequests.create(test_request,
                                                                         "7488a646-e31f-11e4-aace-600308960662",
                                                                         @legal_entity_id)
    medication_request_request
  end

  setup %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity, id: @legal_entity_id)
    division = insert(:prm, :division,
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        legal_entity: legal_entity,
        is_active: true)
    employee = insert(:prm, :employee,
        id: "7488a646-e31f-11e4-aace-600308960662",
        legal_entity: legal_entity,
        division: division
    )
    party_id = employee.party |> Map.get(:id)
    user_id = Ecto.UUID.generate()
    EHealth.PRMRepo.insert!(%EHealth.PartyUsers.PartyUser{user_id: user_id, party_id: party_id})
    conn =
     conn
     |> put_consumer_id_header(user_id)
     |> put_client_id_header(legal_entity.id)
    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all medication_request_requests", %{conn: conn} do
      conn = get conn, medication_request_request_path(conn, :index, %{})
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all medication_request_requests with data", %{conn: conn} do
      mrr = fixture(:medication_request_request)
      conn = get conn, medication_request_request_path(conn, :index,
        %{"employee_id" => mrr.medication_request_request.data.employee_id})
      assert length(json_response(conn, 200)["data"]) == 1
      assert :ok == validate_response_with_schema(json_response(conn, 200)["data"],
        "specs/json_schemas/medication_request_request/medication_request_request_get_list_response.json")
    end

    test "lists all medication_request_requests with data search by status", %{conn: conn} do
      fixture(:medication_request_request)
      conn = get conn, medication_request_request_path(conn, :index,
        %{"status" => "NEW"})
      assert length(json_response(conn, 200)["data"]) == 1
      assert :ok == validate_response_with_schema(json_response(conn, 200)["data"],
        "specs/json_schemas/medication_request_request/medication_request_request_get_list_response.json")
    end

    test "lists all medication_request_requests with data search by person_id", %{conn: conn} do
      mrr = fixture(:medication_request_request)
      conn = get conn, medication_request_request_path(conn, :index,
        %{"person_id" =>  mrr.medication_request_request.data.person_id})
      assert length(json_response(conn, 200)["data"]) == 1
      assert :ok == validate_response_with_schema(json_response(conn, 200)["data"],
        "specs/json_schemas/medication_request_request/medication_request_request_get_list_response.json")
    end

    test "lists all medication_request_requests with data search by all posible filters", %{conn: conn} do
      mrr = fixture(:medication_request_request)
      conn = get conn, medication_request_request_path(conn, :index,
        %{"person_id" =>  mrr.medication_request_request.data.person_id,
          "employee_id" => mrr.medication_request_request.data.employee_id,
          "status" => "NEW"})
      assert length(json_response(conn, 200)["data"]) == 1
      assert :ok == validate_response_with_schema(json_response(conn, 200)["data"],
        "specs/json_schemas/medication_request_request/medication_request_request_get_list_response.json")
    end
  end

  describe "create medication_request_request" do
    test "render medication_request_request when data is valid", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)
      conn1 = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert %{"id" => id} = json_response(conn1, 201)["data"]
      assert :ok == validate_response_with_schema(json_response(conn1, 201)["data"],
        "specs/json_schemas/medication_request_request/medication_request_request_create_response.json")

      conn1 = get conn, medication_request_request_path(conn, :show, id)
      assert :ok == validate_response_with_schema(json_response(conn1, 200)["data"],
        "specs/json_schemas/medication_request_request/medication_request_request_create_response.json")
      conn2 = get conn, medication_request_request_path(conn, :index, %{})
      assert length(json_response(conn2, 200)["data"]) == 1
    end

    test "render errors when data is invalid", %{conn: conn} do
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: %{}
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "render errors when person_id is invalid", %{conn: conn} do
      test_request =
        test_request()
        |> Map.put("person_id", "585041f5-1272-4bca-8d41-8440eefe7d26")
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.person_id"
    end

    test "render errors when employee_id is invalid", %{conn: conn} do
      test_request =
        test_request()
        |> Map.put("employee_id", "585041f5-1272-4bca-8d41-8440eefe7d26")
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.employee_id"
    end

    test "render errors when division_id is invalid", %{conn: conn} do
      test_request =
        test_request()
        |> Map.put("division_id", "585041f5-1272-4bca-8d41-8440eefe7d26")
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.division_id"
    end

    test "render errors when declaration doesn't exists", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("person_id", "575041f5-1272-4bca-8d41-8440eefe7d26")
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      error_msg =
        conn
        |> json_response(422)
        |> get_in(["error", "invalid"])
        |> List.first
        |> Map.get("rules")
        |> List.first
        |> Map.get("description")
      assert error_msg == "Only doctors with an active declaration with the patient can create medication request!"
    end

    test "render errors when ended_at < started_at", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)
        |> Map.put("ended_at", to_string(Timex.shift(Timex.today, days: 2)))
        |> Map.put("started_at", to_string(Timex.shift(Timex.today, days: 3)))
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.ended_at"
    end

    test "render errors when started_at < created_at", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)
        |> Map.put("started_at", to_string(Timex.shift(Timex.today, days: 2)))
        |> Map.put("created_at", to_string(Timex.shift(Timex.today, days: 3)))
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.started_at"
    end

    test "render errors when started_at < today", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)
        |> Map.put("started_at", to_string(Timex.shift(Timex.today, days: -2)))

      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.started_at"
    end

    test "render errors when medication doesn't exists", %{conn: conn} do
      {_, pm} = create_medications_structure()
      {medication_id1, _} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id1)
        |> Map.put("medical_program_id", pm.medical_program_id)

      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      error_msg =
        conn
        |> json_response(422)
        |> get_in(["error", "invalid"])
        |> List.first
        |> Map.get("rules")
        |> List.first
        |> Map.get("description")
      assert error_msg == "Not found any medications allowed for create medication request for this medical program!"
    end

    test "render errors when medication_qty is invalid", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medication_qty", 7)
        |> Map.put("medical_program_id", pm.medical_program_id)

      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      error_msg =
        conn
        |> json_response(422)
        |> get_in(["error", "invalid"])
        |> List.first
        |> Map.get("rules")
        |> List.first
        |> Map.get("description")
      assert error_msg ==
        "The amount of medications in medication request must be divisible to package minimum quantity"
    end

    test "render medication_request_request when medication created with different qty", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()

      %{id: med_id1} = insert(:prm, :medication, [
        name: "Бупропіонол TEST",
        package_qty: 20,
        package_min_qty: 10,
      ])

      insert(:prm, :ingredient_medication, parent_id: med_id1, medication_child_id: medication_id)
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medication_qty", 5)
        |> Map.put("medical_program_id", pm.medical_program_id)

      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 201)
    end

    test "render errors when medication_program is invalid", %{conn: conn} do
      {medication_id, _} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", Ecto.UUID.generate)

      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.medical_program_id"
    end
  end

  describe "prequalify medication request request" do
    test "works when data is valid", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()

      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.delete("medical_program_id")
      conn1 = post conn, medication_request_request_path(conn, :prequalify), %{medication_request_request: test_request,
        programs: [%{id: pm.medical_program_id}]}
      assert %{"status" => "VALID"} = json_response(conn1, 200)["data"] |> Enum.at(0)
       assert :ok == validate_response_with_schema(json_response(conn1, 200)["data"],
        "specs/json_schemas/medication_request_request/medication_request_request_prequalify_response.json")

      assert is_list(json_response(conn1, 200)["data"] |> Enum.at(0) |> Map.get("participants"))
    end

    test "show proper message when program medication is invalid", %{conn: conn} do
      {medication_id, _} = create_medications_structure()
      pm1 = insert(:prm, :program_medication)
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.delete("medical_program_id")
      conn1 = post conn, medication_request_request_path(conn, :prequalify), %{medication_request_request: test_request,
        programs: [%{id: pm1.medical_program_id}]}
      assert %{
        "status" => "INVALID",
        "rejection_reason" => ~s(Innm not on the list of approved innms for program "Доступні ліки")
      } = json_response(conn1, 200)["data"] |> Enum.at(0)
    end

    test "render error when data is invalid", %{conn: conn} do
      test_request =
        test_request()
        |> Map.put("person_id", "")
      conn1 = post conn, medication_request_request_path(conn, :prequalify), %{medication_request_request: test_request,
        programs: []}
      assert json_response(conn1, 422)
    end
  end

  describe "reject medication request request" do
    test "works when data is valid", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)
      conn1 = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert %{"id" => id} = json_response(conn1, 201)["data"]

      conn2 = patch conn, medication_request_request_path(conn, :reject, id)
      assert %{"id" => id1} = json_response(conn2, 200)["data"]
      assert id == id1

      conn3 = patch conn, medication_request_request_path(conn, :reject, id)
      assert json_response(conn3, 409)
    end

    test "works when data is invalid", %{conn: conn} do
      conn1 = patch conn, medication_request_request_path(conn, :reject, Ecto.UUID.generate())
      assert json_response(conn1, 404)
    end
  end

  describe "autotermination works fine" do
    test "with direct call", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)
      conn1 = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert %{"id" => id} = json_response(conn1, 201)["data"]

      EHealth.Repo.update_all(EHealth.MedicationRequestRequest, set: [inserted_at: ~N[1970-01-01 13:26:08.003]])
      MedicationRequestRequests.autoterminate()
      mrr = MedicationRequestRequests.get_medication_request_request(id)
      assert mrr.status == "EXPIRED"
      assert mrr.updated_by == Confex.fetch_env!(:ehealth, :system_user)
    end
  end

  describe "sign medication request request" do
    test "when data is valid", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)
      conn1 = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert mrr = json_response(conn1, 201)["data"]

      signed_mrr =
        mrr
        |> Poison.encode!()
        |> Base.encode64()

      drfo =
        mrr
        |> get_in(["employee", "party", "id"])
        |> (fn x -> EHealth.PRMRepo.get!(EHealth.Parties.Party, x) end).()
        |> Map.get(:tax_id)
      conn = Plug.Conn.put_req_header(conn, "drfo", drfo)

      conn1 = patch conn, medication_request_request_path(conn, :sign, mrr["id"]),
        %{signed_medication_request_request: signed_mrr, signed_content_encoding: "base64"}
      assert json_response(conn1, 200)
      assert json_response(conn1, 200)["data"]["status"] == "ACTIVE"
    end

    test "return 404 if request not found", %{conn: conn} do
      conn1 = patch conn, medication_request_request_path(conn, :sign, Ecto.UUID.generate()),
      %{signed_medication_request_request: "", signed_content_encoding: "base64"}
      assert json_response(conn1, 404)
    end

    test "return 409 if request status is not new", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
        test_request =
          test_request()
          |> Map.put("medication_id", medication_id)
          |> Map.put("medical_program_id", pm.medical_program_id)
      conn1 = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert mrr = json_response(conn1, 201)["data"]

      EHealth.Repo.update_all(EHealth.MedicationRequestRequest, set: [status: "EXPIRED"])

      conn1 = patch conn, medication_request_request_path(conn, :sign, mrr["id"]),
      %{signed_medication_request_request: "", signed_content_encoding: "base64"}
      assert json_response(conn1, 409)
    end

    test "return 422 if request is not valid", %{conn: conn} do
      conn1 = patch conn, medication_request_request_path(conn, :sign, Ecto.UUID.generate()),
      %{signed_medication_request_request: %{}, signed_content_encoding: "base64"}
      assert json_response(conn1, 422)
    end

     test "when some data is invalid", %{conn: conn} do
      {medication_id, pm} = create_medications_structure()
      test_request =
        test_request()
        |> Map.put("medication_id", medication_id)
        |> Map.put("medical_program_id", pm.medical_program_id)

      conn1 = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert mrr = json_response(conn1, 201)["data"]

      signed_mrr =
        mrr
        |> put_in(["employee", "id"], Ecto.UUID.generate)
        |> Poison.encode!()
        |> Base.encode64()

      conn1 = patch conn, medication_request_request_path(conn, :sign, mrr["id"]),
        %{signed_medication_request_request: signed_mrr, signed_content_encoding: "base64"}
      assert json_response(conn1, 422)
    end
  end

  defp create_medications_structure do
    %{id: innm_id} = insert(:prm, :innm, name: "Будафинол")
    %{id: dosage_id} = insert(:prm, :innm_dosage, name: "Будафинолон Альтернативний")
    %{id: dosage_id2} = insert(:prm, :innm_dosage, name: "Будафинолон Альтернативний 2")
    %{id: med_id} = insert(:prm, :medication, package_qty: 10, package_min_qty: 5, name: "Будафинолодон")
    %{id: med_id2} = insert(:prm, :medication, package_qty: 10, package_min_qty: 5, name: "Будафинолодон2")
    insert(:prm, :ingredient_innm_dosage, [parent_id: dosage_id, innm_child_id: innm_id])
    insert(:prm, :ingredient_innm_dosage, [parent_id: dosage_id2, innm_child_id: innm_id])
    insert(:prm, :ingredient_medication, [parent_id: med_id, medication_child_id: dosage_id])
    insert(:prm, :ingredient_medication, [parent_id: med_id2, medication_child_id: dosage_id2])

    pm = insert(:prm, :program_medication, [medication_id: med_id])
    insert(:prm, :program_medication, [medication_id: med_id2, medical_program_id: pm.medical_program_id])

    {dosage_id, pm}
  end

  defp test_request do
    "test/data/medication_request_request/medication_request_request.json"
    |> File.read!()
    |> Poison.decode!
  end

  defp validate_response_with_schema(resp, schema_path) do
    schema =
      schema_path
      |> File.read!()
      |> Poison.decode!()

    NExJsonSchema.Validator.validate(schema, resp)
  end
end
