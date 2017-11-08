defmodule EHealth.Web.MedicationDispenseControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.MockServer, only: [
    get_inactive_medication_request: 0,
    get_invalid_medication_request_period: 0,
    get_active_medication_dispense: 0,
    get_inactive_medication_dispense: 0
  ]
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  describe "create medication dispense" do
    test "invalid legal_entity", %{conn: conn} do
      legal_entity_id = Ecto.UUID.generate()
      conn = put_client_id_header(conn, legal_entity_id)
      conn = post conn, medication_dispense_path(conn, :create), medication_dispense: new_dispense_params()
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.legal_entity_id"}]}} = resp
    end

    test "invalid medication_request", %{conn: conn} do
      %{user_id: user_id} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params(%{"medication_request_id" => Ecto.UUID.generate()})
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.medication_request_id"}]}} = resp
    end

    test "medication_request is not active", %{conn: conn} do
      %{user_id: user_id} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create), medication_dispense: new_dispense_params(%{
        "medication_request_id" => get_inactive_medication_request()
      })
      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Medication request is not active"}} = resp
    end

    test "invalid medication dispense period", %{conn: conn} do
      %{user_id: user_id} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create), medication_dispense: new_dispense_params(%{
            "medication_request_id" => get_invalid_medication_request_period()
                                                                                                          })
      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Invalid dispense period"}} = resp
    end

    test "invalid party", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params()
      assert resp = json_response(conn, 400)
      assert %{"error" => %{"message" => "Party not found"}} = resp
    end

    test "no active employee", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity, id: "dae597a8-c858-42f6-bc16-1a7bdd340466")
      insert_employee(party)
      insert_division(legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params()
      assert json_response(conn, 403)
    end

    test "invalid division", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert_legal_entity()
      insert_division(legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params()
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.division_id"}]}} = resp
    end

    test "division is not active", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert_legal_entity()
      insert_division(legal_entity)
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      division = insert(:prm, :division)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id
        })
      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Division is not active"}} = resp
    end

    test "invalid medical program", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      division = insert_division(legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id,
          "medical_program_id" => Ecto.UUID.generate(),
        })
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.medical_program_id"}]}} = resp
    end

    test "medical program is not active", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      division = insert_division(legal_entity)
      medication = insert_medication(innm_dosage_id)
      medical_program = insert_medical_program(false)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id,
          "medical_program_id" => medical_program.id,
          "dispense_details" => [
            %{
              "medication_id": medication.id,
              "medication_qty": 10,
              "sell_price": 18.65,
              "sell_amount": 186.5,
              "discount_amount": 150,
            }
          ],
        })
      resp = json_response(conn, 409)
      assert %{"error" => %{"type" => "request_conflict", "message" => "Medical program is not active"}} = resp
    end

    test "invalid medication", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      division = insert_division(legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id,
        })
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.dispense_details[0].medication_id"}]}} = resp
    end

    test "medication is not active", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      division = insert_division(legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        code: "anything",
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id,
        })
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.dispense_details[0].medication_id"}]}} = resp
    end

    test "medication is not a participant of program", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      division = insert_division(legal_entity)
      medication = insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id,
          "dispense_details" => [
            %{
              "medication_id": medication.id,
              "medication_qty": 10,
              "sell_price": 18.65,
              "sell_amount": 186.5,
              "discount_amount": 50,
            }
          ],
        })
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.dispense_details[0].medication_id"}]}} = resp
    end

    test "invalid code", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      division = insert_division(legal_entity)
      medication = insert_medication(innm_dosage_id)
      %{id: medical_program_id} = insert_medical_program()
      insert(:prm, :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id,
          "dispense_details" => [
            %{
              "medication_id": medication.id,
              "medication_qty": 10,
              "sell_price": 18.65,
              "sell_amount": 186.5,
              "discount_amount": 50,
            }
          ],
        })
      assert json_response(conn, 401)
    end

    test "requested reimbursement is higher than allowed", %{conn: conn} do
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity, id: "dae597a8-c858-42f6-bc16-1a7bdd340466")
      insert(:prm, :employee,
        legal_entity: legal_entity,
        party: party,
        id: "46be2081-4bd2-4a7e-8999-2f6ce4b57dab"
      )
      division = insert(:prm, :division,
        is_active: true,
        legal_entity: legal_entity,
        id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c"
      )
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      medical_program_id = "6ee844fd-9f4d-4457-9eda-22aa506be4c4"
      insert(:prm, :medical_program, id: medical_program_id)
      insert(:prm, :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id
      )
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        code: "1234",
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id,
          "dispense_details" => [
            %{
              "medication_id": medication.id,
              "medication_qty": 10,
              "sell_price": 18.65,
              "sell_amount": 186.5,
              "discount_amount": 150,
            }
          ],
        })
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.dispense_details[0].discount_amount"}]}} = resp
    end

    test "success create medication dispense", %{conn: conn} do
      insert(:prm, :medication, id: "340ef14a-ab9b-4303-b01b-d40a2237e512")
      %{user_id: user_id, party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity, id: "dae597a8-c858-42f6-bc16-1a7bdd340466")
      insert(:prm, :employee,
        legal_entity: legal_entity,
        party: party,
        id: "46be2081-4bd2-4a7e-8999-2f6ce4b57dab"
      )
      division = insert(:prm, :division,
        is_active: true,
        legal_entity: legal_entity,
        id: "e00e20ba-d20f-4ebb-a1dc-4bf58231019c"
      )
      %{id: innm_dosage_id} = insert_innm_dosage()
      medication = insert_medication(innm_dosage_id)
      medical_program_id = "6ee844fd-9f4d-4457-9eda-22aa506be4c4"
      insert(:prm, :medical_program, id: medical_program_id)
      insert(:prm, :program_medication,
        medication_id: medication.id,
        medical_program_id: medical_program_id,
        reimbursement: build(:reimbursement, reimbursement_amount: 150)
      )
      conn = put_client_id_header(conn, legal_entity.id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn = post conn, medication_dispense_path(conn, :create),
        code: "1234",
        medication_dispense: new_dispense_params(%{
          "division_id" => division.id,
          "dispense_details" => [
            %{
              "medication_id": medication.id,
              "medication_qty": 10,
              "sell_price": 18.65,
              "sell_amount": 186.5,
              "discount_amount": 50,
            }
          ],
        })
      resp = json_response(conn, 201)

      schema =
        "specs/json_schemas/medication_dispense/medication_dispense_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "show medication dispense" do
    test "success show by id", %{conn: conn} do
      insert(:prm, :medication, id: "340ef14a-ab9b-4303-b01b-d40a2237e512")
      party = insert(:prm, :party, id: "02852372-9e06-11e7-abc4-cec278b6b50a")
      insert(:prm, :party_user, party: party)
      legal_entity = insert_legal_entity("5243c8e6-9e06-11e7-abc4-cec278b6b50a")
      insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      insert_division(legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get conn, medication_dispense_path(conn, :show, get_active_medication_dispense())

      schema =
        "specs/json_schemas/medication_dispense/medication_dispense_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      resp = json_response(conn, 200)["data"]
      :ok = NExJsonSchema.Validator.validate(schema, resp)
    end
  end

  describe "list medication dispenses" do
    test "success list", %{conn: conn} do
      insert(:prm, :medication, id: "340ef14a-ab9b-4303-b01b-d40a2237e512")
      party = insert(:prm, :party, id: "02852372-9e06-11e7-abc4-cec278b6b50a")
      insert(:prm, :party_user, party: party)
      legal_entity = insert_legal_entity("5243c8e6-9e06-11e7-abc4-cec278b6b50a")
      insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      insert_division(legal_entity)
      insert_division(legal_entity, "f2f76cf8-9e05-11e7-abc4-cec278b6b50a")
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get conn, medication_dispense_path(conn, :index)
      resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/medication_dispense/medication_dispense_list_response.json"
        |> File.read!()
        |> Poison.decode!()
      :ok = NExJsonSchema.Validator.validate(schema, resp)
    end
  end

  describe "process medication dispense" do
    test "success process", %{conn: conn} do
      insert(:prm, :medication, id: "340ef14a-ab9b-4303-b01b-d40a2237e512")
      party = insert(:prm, :party, id: "02852372-9e06-11e7-abc4-cec278b6b50a")
      insert(:prm, :party_user, party: party)
      legal_entity = insert_legal_entity("5243c8e6-9e06-11e7-abc4-cec278b6b50a")
      insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      insert_division(legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      payment_id = "12345"
      conn = put_client_id_header(conn, legal_entity.id)
      path = medication_dispense_path(conn, :process, get_active_medication_dispense())
      conn = patch conn, path, %{"payment_id" => payment_id}
      resp = json_response(conn, 200)["data"]
      schema =
        "specs/json_schemas/medication_dispense/medication_dispense_show_response.json"
        |> File.read!()
        |> Poison.decode!()
      :ok = NExJsonSchema.Validator.validate(schema, resp)
      assert "PROCESSED" == resp["status"]
      assert payment_id == resp["payment_id"]
    end

    test "fail to find medication dispense", %{conn: conn} do
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      conn = patch conn, medication_dispense_path(conn, :process, Ecto.UUID.generate())
      assert json_response(conn, 404)
    end

    test "invalid legal_entity_id", %{conn: conn} do
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      conn = patch conn, medication_dispense_path(conn, :process, get_active_medication_dispense())
      assert json_response(conn, 404)
    end

    test "invalid transition", %{conn: conn} do
      insert(:prm, :medication, id: "340ef14a-ab9b-4303-b01b-d40a2237e512")
      party = insert(:prm, :party, id: "02852372-9e06-11e7-abc4-cec278b6b50a")
      insert(:prm, :party_user, party: party)
      legal_entity = insert_legal_entity("5243c8e6-9e06-11e7-abc4-cec278b6b50a")
      insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      insert_division(legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      path = medication_dispense_path(conn, :process, get_inactive_medication_dispense())
      conn = patch conn, path, %{"payment_id" => "12345"}
      assert json_response(conn, 409)
    end
  end

  describe "reject medication dispense" do
    test "success reject", %{conn: conn} do
      insert(:prm, :medication, id: "340ef14a-ab9b-4303-b01b-d40a2237e512")
      party = insert(:prm, :party, id: "02852372-9e06-11e7-abc4-cec278b6b50a")
      insert(:prm, :party_user, party: party)
      legal_entity = insert_legal_entity("5243c8e6-9e06-11e7-abc4-cec278b6b50a")
      insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      insert_division(legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      payment_id = "12345"
      conn = put_client_id_header(conn, legal_entity.id)
      path = medication_dispense_path(conn, :reject, get_active_medication_dispense())
      conn = patch conn, path, %{"payment_id" => payment_id}
      resp = json_response(conn, 200)["data"]
      schema =
        "specs/json_schemas/medication_dispense/medication_dispense_show_response.json"
        |> File.read!()
        |> Poison.decode!()
      :ok = NExJsonSchema.Validator.validate(schema, resp)
      assert "REJECTED" == resp["status"]
      assert payment_id == resp["payment_id"]
    end

    test "fail to find medication dispense", %{conn: conn} do
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      conn = patch conn, medication_dispense_path(conn, :reject, Ecto.UUID.generate())
      assert json_response(conn, 404)
    end

    test "invalid legal_entity_id", %{conn: conn} do
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      conn = patch conn, medication_dispense_path(conn, :reject, get_active_medication_dispense())
      assert json_response(conn, 404)
    end

    test "invalid transition", %{conn: conn} do
      insert(:prm, :medication, id: "340ef14a-ab9b-4303-b01b-d40a2237e512")
      party = insert(:prm, :party, id: "02852372-9e06-11e7-abc4-cec278b6b50a")
      insert(:prm, :party_user, party: party)
      legal_entity = insert_legal_entity("5243c8e6-9e06-11e7-abc4-cec278b6b50a")
      insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      insert_division(legal_entity)
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      path = medication_dispense_path(conn, :process, get_inactive_medication_dispense())
      conn = patch conn, path, %{"payment_id" => "12345"}
      assert json_response(conn, 409)
    end
  end

  describe "list by medication_request_id" do
    test "success list", %{conn: conn} do
      id = "4bbaf78e-d382-4a6d-93c6-e96b44a5107d"
      user_id = get_consumer_id(conn.req_headers)
      insert(:prm, :medication, id: "340ef14a-ab9b-4303-b01b-d40a2237e512")
      insert(:prm, :party_user, user_id: user_id)

      party = insert(:prm, :party, id: "02852372-9e06-11e7-abc4-cec278b6b50a", tax_id: "test")
      insert(:prm, :party_user, party: party)
      legal_entity = insert_legal_entity("5243c8e6-9e06-11e7-abc4-cec278b6b50a")
      insert_legal_entity()
      %{id: innm_dosage_id} = insert_innm_dosage()
      insert_employee(party, legal_entity)
      insert_division(legal_entity)
      insert_division(legal_entity, "f2f76cf8-9e05-11e7-abc4-cec278b6b50a")
      insert_medication(innm_dosage_id)
      insert_medical_program()
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get conn, medication_dispense_path(conn, :by_medication_request, id)
      resp = json_response(conn, 200)
      assert 1 == length(resp["data"])
      assert id == resp["data"] |> hd |> get_in(~w(medication_request id))

      schema =
        "specs/json_schemas/medication_dispense/medication_dispense_list_response.json"
        |> File.read!()
        |> Poison.decode!()
      :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "party_user not found", %{conn: conn} do
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      conn = get conn, medication_dispense_path(conn, :by_medication_request, Ecto.UUID.generate())
      assert json_response(conn, 500)
    end
  end

  defp new_dispense_params(params \\ %{}) do
    Map.merge(%{
      "medication_request_id": "f08ba3a3-157a-4adc-b65d-737f24f3a1f4",
      "dispensed_at": "2017-08-17",
      "employee_id": "6d987b5d-6d72-40bc-9cf7-1304b32ed5bb",
      "division_id": "2fc70f30-08dc-493c-8d08-925905d7b1e8",
      "medical_program_id": "6ee844fd-9f4d-4457-9eda-22aa506be4c4",
      "dispense_details": [
        %{
          "medication_id": "a808bc3e-738d-442e-a2f4-0e5477695602",
          "medication_qty": 10,
          "sell_price": 18.65,
          "sell_amount": 186.5,
          "discount_amount": 150,
        }
      ]
    }, params)
  end

  defp insert_division(legal_entity, id \\ "e00e20ba-d20f-4ebb-a1dc-4bf58231019c") do
    insert(:prm, :division,
      is_active: true,
      legal_entity: legal_entity,
      id: id
    )
  end

  defp insert_medication(innm_dosage_id) do
    id = Ecto.UUID.generate()
    insert(:prm, :medication,
      id: id,
      ingredients: [
        build(:ingredient_medication,
          medication_child_id: innm_dosage_id,
          parent_id: id
        )
      ]
    )
  end

  defp insert_medical_program(is_active \\ true) do
    insert(:prm, :medical_program, id: "6ee844fd-9f4d-4457-9eda-22aa506be4c4", is_active: is_active)
  end

  defp insert_employee(party, legal_entity \\ nil) do
    params = [party: party, id: "46be2081-4bd2-4a7e-8999-2f6ce4b57dab"]
    params = if legal_entity, do: Keyword.put(params, :legal_entity, legal_entity), else: params
    insert(:prm, :employee, params)
  end

  defp insert_legal_entity(id \\ "dae597a8-c858-42f6-bc16-1a7bdd340466") do
    insert(:prm, :legal_entity, id: id)
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
