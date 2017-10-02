defmodule EHealth.Web.MedicationDispenseControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.MockServer, only: [
    get_inactive_medication_request: 0,
    get_invalid_medication_request_period: 0,
    get_active_medication_dispense: 0,
    get_inactive_medication_dispense: 0
  ]

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

    test "invalid code", %{conn: conn} do
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
              "discount_amount": 150,
            }
          ],
        })
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.code"}]}} = resp
    end

    test "success create medication dispense", %{conn: conn} do
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
      medication = insert(:prm, :medication,
        id: "2cdb8396-a1e9-11e7-abc4-cec278b6b50a",
        ingredients: [build(:ingredient_medication,
                       id: "2cdb8396-a1e9-11e7-abc4-cec278b6b50a",
                       medication_child_id: innm_dosage_id,
                       parent_id: "2cdb8396-a1e9-11e7-abc4-cec278b6b50a"
                     )],
      )
      insert(:prm, :medical_program, id: "6ee844fd-9f4d-4457-9eda-22aa506be4c4")
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
      resp = json_response(conn, 201)

      schema =
        "test/data/medication_dispense/create_medication_dispense_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "show medication dispense" do
    test "success show by id", %{conn: conn} do
      %{party: party} = insert(:prm, :party_user)
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
        "test/data/medication_dispense/get_medication_dispense_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      resp = json_response(conn, 200)["data"]
      :ok = NExJsonSchema.Validator.validate(schema, resp)
    end
  end

  describe "list medication dispenses" do
    test "success list", %{conn: conn} do
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
        "test/data/medication_dispense/list_medication_dispenses_response_schema.json"
        |> File.read!()
        |> Poison.decode!()
      :ok = NExJsonSchema.Validator.validate(schema, resp)
    end
  end

  describe "process medication dispense" do
    test "success process", %{conn: conn} do
      %{party: party} = insert(:prm, :party_user)
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
        "test/data/medication_dispense/get_medication_dispense_response_schema.json"
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
      %{party: party} = insert(:prm, :party_user)
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
      %{party: party} = insert(:prm, :party_user)
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
        "test/data/medication_dispense/get_medication_dispense_response_schema.json"
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
      %{party: party} = insert(:prm, :party_user)
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
    insert(:prm, :medication,
      id: "2cdb8396-a1e9-11e7-abc4-cec278b6b50a",
      ingredients: [
        build(:ingredient_medication,
          id: "2cdb8396-a1e9-11e7-abc4-cec278b6b50a",
          medication_child_id: innm_dosage_id,
          parent_id: "2cdb8396-a1e9-11e7-abc4-cec278b6b50a"
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
    innm_dosage = insert(:prm, :innm_dosage)
    insert(:prm, :ingredient_innm_dosage, [innm_child_id: innm_id, parent_id: innm_dosage.id])

    innm_dosage
  end
end
