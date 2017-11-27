defmodule EHealth.Web.MedicationRequestControllerTest do

  use EHealth.Web.ConnCase, async: true
  alias EHealth.PRMRepo
  alias EHealth.LegalEntities.LegalEntity
  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import EHealth.MockServer, only: [get_active_medication_request: 0, get_client_admin: 0]

  setup %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    {:ok, conn: put_client_id_header(conn, id)}
  end

  describe "list medication requests" do
    test "success list medication requests", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      insert(:prm, :division, id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c")
      insert(:prm, :legal_entity, id: "dae597a8-c858-42f6-bc16-1a7bdd340466")
      insert(:prm, :medical_program, id: "6ee844fd-9f4d-4457-9eda-22aa506be4c4")
      insert_innm_dosage()

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      person_id = Ecto.UUID.generate()
      conn = get conn, medication_request_path(conn, :index, %{"page_size" => 1}), %{
        "employee_id" => employee_id,
        "person_id" => person_id,
      }
      resp = json_response(conn, 200)
      assert 1 == length(resp["data"])

      schema =
        "specs/json_schemas/medication_request/medication_request_list_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "no party user", %{conn: conn} do
      conn = get conn, medication_request_path(conn, :index)
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
      conn = get conn, medication_request_path(conn, :index), %{"employee_id" => Ecto.UUID.generate()}
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
      conn = get conn, medication_request_path(conn, :index)
      assert json_response(conn, 500)
    end
  end

  describe "show medication_request" do
    test "success get medication_request by id", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      insert(:prm, :division, id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c")
      insert(:prm, :legal_entity, id: "dae597a8-c858-42f6-bc16-1a7bdd340466")
      insert(:prm, :medical_program, id: "6ee844fd-9f4d-4457-9eda-22aa506be4c4")
      insert_innm_dosage()

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      insert(:prm, :employee, party: party, legal_entity: legal_entity)
      conn = get conn, medication_request_path(conn, :show, get_active_medication_request())
      resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/medication_request/medication_request_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "no party user", %{conn: conn} do
      conn = get conn, medication_request_path(conn, :show, Ecto.UUID.generate())
      assert json_response(conn, 500)
    end

    test "not found", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      insert(:prm, :party_user, user_id: user_id)
      conn = get conn, medication_request_path(conn, :show, "e9baba39-da78-4950-b396-cc36e80572b1")
      assert json_response(conn, 404)
    end
  end

  describe "qualify medication request" do
    test "success qualify", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      insert(:prm, :division, id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c")
      insert(:prm, :legal_entity, id: "dae597a8-c858-42f6-bc16-1a7bdd340466")
      medical_program_id = "6ee844fd-9f4d-4457-9eda-22aa506be4c4"
      insert(:prm, :medical_program, id: medical_program_id)
      %{medication_id: medication_id} = insert(:prm, :program_medication,
        medical_program_id: medical_program_id
      )

      %{id: innm_dosage_id} = insert_innm_dosage()
      insert(:prm, :ingredient_medication,
        parent_id: medication_id,
        medication_child_id: innm_dosage_id
      )

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      insert(:prm, :employee, party: party, legal_entity: legal_entity)
      conn = post conn, medication_request_path(conn, :qualify, get_active_medication_request()), %{
        "programs" => [%{"id" => medical_program_id}]
      }
      resp = json_response(conn, 200)
      schema =
        "specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "success qualify as admin", %{conn: conn} do
      insert(:prm, :division, id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c")
      medical_program_id = "6ee844fd-9f4d-4457-9eda-22aa506be4c4"
      insert(:prm, :medical_program, id: medical_program_id)
      %{medication_id: medication_id} = insert(:prm, :program_medication,
        medical_program_id: medical_program_id
      )

      %{id: innm_dosage_id} = insert_innm_dosage()
      insert(:prm, :ingredient_medication,
        parent_id: medication_id,
        medication_child_id: innm_dosage_id
      )

      conn = put_client_id_header(conn, get_client_admin())
      conn = post conn, medication_request_path(conn, :qualify, get_active_medication_request()), %{
        "programs" => [%{"id" => medical_program_id}]
      }
      resp = json_response(conn, 200)
      schema =
        "specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "INVALID qualify as admin", %{conn: conn} do
      insert(:prm, :division, id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c")
      medical_program_id = "6ee844fd-9f4d-4457-9eda-22aa506be4c4"
      insert(:prm, :medical_program, id: medical_program_id)
      insert(:prm, :program_medication, medical_program_id: medical_program_id)
      insert_innm_dosage()

      conn = put_client_id_header(conn, get_client_admin())
      conn = post conn, medication_request_path(conn, :qualify, get_active_medication_request()), %{
        "programs" => [%{"id" => medical_program_id}]
      }
      resp = json_response(conn, 200)
      schema =
        "specs/json_schemas/medication_request/medication_request_qualify_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "failed validation", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      insert(:prm, :party_user, user_id: user_id)
      conn = post conn, medication_request_path(conn, :qualify, get_active_medication_request())
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.programs"}]}} = resp
    end

    test "medication_request not found", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      insert(:prm, :party_user, user_id: user_id)
      conn = post conn, medication_request_path(conn, :qualify, "e9baba39-da78-4950-b396-cc36e80572b1")
      assert json_response(conn, 404)
    end

    test "program medication not found", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      insert(:prm, :party_user, user_id: user_id)
      conn = post conn, medication_request_path(conn, :qualify, get_active_medication_request()), %{
        "programs" => [%{"id" => Ecto.UUID.generate()}, %{"id" => Ecto.UUID.generate()}]
      }
      resp = json_response(conn, 422)
      assert 2 == Enum.count(resp["error"]["invalid"])
    end
  end

  describe "reject medication request" do
    test "success", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      insert(:prm, :division, id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c")
      insert(:prm, :legal_entity, id: "dae597a8-c858-42f6-bc16-1a7bdd340466")
      medical_program_id = "6ee844fd-9f4d-4457-9eda-22aa506be4c4"
      insert(:prm, :medical_program, id: medical_program_id)
      %{medication_id: medication_id} = insert(:prm, :program_medication,
        medical_program_id: medical_program_id
      )

      %{id: innm_dosage_id} = insert_innm_dosage()
      insert(:prm, :ingredient_medication,
        parent_id: medication_id,
        medication_child_id: innm_dosage_id
      )

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      insert(:prm, :employee, party: party, legal_entity: legal_entity)
      conn = patch conn, medication_request_path(conn, :reject, get_active_medication_request()),
        %{reject_reason: "TEST"}
      assert json_response(conn, 200)
    end

    test "404", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)

      :prm
      |> insert(:party_user, user_id: user_id)
      |> PRMRepo.preload(:party)
      conn = patch conn, medication_request_path(conn, :reject, "e9baba39-da78-4950-b396-cc36e80572b1"),
        %{reject_reason: "TEST"}
      assert json_response(conn, 404)
    end
  end

  describe "resend medication request info" do
    test "success", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)
      legal_entity_id = get_client_id(conn.req_headers)
      insert(:prm, :division, id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c")
      insert(:prm, :legal_entity, id: "dae597a8-c858-42f6-bc16-1a7bdd340466")
      medical_program_id = "6ee844fd-9f4d-4457-9eda-22aa506be4c4"
      insert(:prm, :medical_program, id: medical_program_id)
      %{medication_id: medication_id} = insert(:prm, :program_medication,
        medical_program_id: medical_program_id
      )

      %{id: innm_dosage_id} = insert_innm_dosage()
      insert(:prm, :ingredient_medication,
        parent_id: medication_id,
        medication_child_id: innm_dosage_id
      )

      %{party: party} =
        :prm
        |> insert(:party_user, user_id: user_id)
        |> PRMRepo.preload(:party)
      legal_entity = PRMRepo.get!(LegalEntity, legal_entity_id)
      insert(:prm, :employee, party: party, legal_entity: legal_entity)
      conn = patch conn, medication_request_path(conn, :resend, get_active_medication_request())
      assert json_response(conn, 200)
    end

    test "404", %{conn: conn} do
      user_id = get_consumer_id(conn.req_headers)

      :prm
      |> insert(:party_user, user_id: user_id)
      |> PRMRepo.preload(:party)
      conn = patch conn, medication_request_path(conn, :resend, "e9baba39-da78-4950-b396-cc36e80572b1")
      assert json_response(conn, 404)
    end
  end
  def insert_innm_dosage do
    %{id: innm_id} = insert(:prm, :innm)

    insert(:prm, :innm_dosage,
      id: "2cdb8396-a1e9-11e7-abc4-cec278b6b50a",
      ingredients: [
        build(:ingredient_innm_dosage,
          innm_child_id: innm_id,
          parent_id: "2cdb8396-a1e9-11e7-abc4-cec278b6b50a"
        )
      ]
    )
  end
end
