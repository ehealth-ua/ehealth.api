defmodule EHealthWeb.ProgramMedicationControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  alias Ecto.UUID
  alias ExMachina.Sequence
  alias EHealth.Medications.Program, as: ProgramMedication

  describe "index" do
    test "empty program_medications list", %{conn: conn} do
      conn = get conn, program_medication_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "search" do
    setup %{conn: conn} do
      Sequence.reset

      innm_dosage1 = insert(:prm, :innm_dosage, name: "Резерпін")
      medication1 = insert(:prm, :medication, name: "Резерпін 20 мг")
      medical_program1 = insert(:prm, :medical_program, name: "Доступні ліки")

      insert(:prm, :ingredient_medication, [parent_id: medication1.id, medication_child_id: innm_dosage1.id])
      insert(:prm, :program_medication, [medication_id: medication1.id, medical_program_id: medical_program1.id])

      innm_dosage = insert(:prm, :innm_dosage, name: "Сульпірид")
      medication = insert(:prm, :medication, name: "Сульпірид 10 мг")
      medical_program = insert(:prm, :medical_program, name: "Щастя в кожен дім")

      insert(:prm, :ingredient_medication, [parent_id: medication.id, medication_child_id: innm_dosage.id])
      insert(:prm, :program_medication, [medication_id: medication.id, medical_program_id: medical_program.id])

      {:ok, %{innm_dosage: innm_dosage, medication: medication, medical_program: medical_program, conn: conn}}
    end

    test "search by medical_program_id", %{conn: conn, medical_program: medical_program} do
      conn = get conn, program_medication_path(conn, :index), medical_program_id: medical_program.id
      data = json_response(conn, 200)["data"]


      assert 1 == length(data)
      assert medical_program.id == data |> List.first() |> get_in(~W(medical_program id))
    end

    test "search by medical_program_name", %{conn: conn, medical_program: medical_program} do
      conn = get conn, program_medication_path(conn, :index), medical_program_name: medical_program.name
      data = json_response(conn, 200)["data"]

      assert 1 == length(data)
      assert medical_program.id == data |> List.first() |> get_in(~W(medical_program id))
    end

    test "search by innm_dosage_id", %{conn: conn, medical_program: medical_program, innm_dosage: innm_dosage} do
      conn = get conn, program_medication_path(conn, :index), innm_dosage_id: innm_dosage.id
      data = json_response(conn, 200)["data"]

      assert 1 == length(data)
      assert medical_program.id == data |> List.first() |> get_in(~W(medical_program id))
    end

    test "search by innm_dosage_name", %{conn: conn, medical_program: medical_program, innm_dosage: innm_dosage} do
      conn = get conn, program_medication_path(conn, :index), innm_dosage_name: innm_dosage.name
      data = json_response(conn, 200)["data"]

      assert 1 == length(data)
      assert medical_program.id == data |> List.first() |> get_in(~W(medical_program id))
    end

    test "search by medication_name", %{conn: conn, medical_program: medical_program, medication: medication} do
      conn = get conn, program_medication_path(conn, :index), medication_name: medication.name
      data = json_response(conn, 200)["data"]

      assert 1 == length(data)
      assert medical_program.id == data |> List.first() |> get_in(~W(medical_program id))
    end
  end

  describe "create program_medication" do
    setup %{conn: conn} do
      Sequence.reset
      {:ok, %{conn: conn}}
    end

    test "renders program_medication when data is valid", %{conn: conn} do
      med_id = insert(:prm, :medication).id
      insert(:prm, :ingredient_medication, [parent_id: med_id, medication_child_id: med_id])
      params = %{
        reimbursement: build(:reimbursement),
        medication_id: med_id,
        medical_program_id: insert(:prm, :medical_program).id,
      }

      conn = post conn, program_medication_path(conn, :create), params
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, program_medication_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert_program_medication_response(resp)
      assert id == resp["data"]["id"]
      assert resp["data"]["medication_request_allowed"]
    end

    test "program medication duplicated", %{conn: conn} do
      program_medication = insert(:prm, :program_medication)
      params = %{
        reimbursement: build(:reimbursement),
        medication_id: program_medication.medication_id,
        medical_program_id: program_medication.medical_program_id,
      }

      conn = post conn, program_medication_path(conn, :create), params
      [error] = json_response(conn, 422)["error"]["invalid"]
      assert "$.medication_id" == error["entry"]
    end

    test "renders errors when medication does not exists", %{conn: conn} do
      params = %{
        reimbursement: build(:reimbursement),
        medication_id: UUID.generate(),
        medical_program_id: insert(:prm, :medical_program).id,
      }
      conn = post conn, program_medication_path(conn, :create), params
      [error] = json_response(conn, 422)["error"]["invalid"]
      assert "$.medication_id" == error["entry"]
    end

    test "renders errors when medication not active", %{conn: conn} do
      med_id = insert(:prm, :medication, is_active: false).id
      params = %{
        reimbursement: build(:reimbursement),
        medication_id: med_id,
        medical_program_id: insert(:prm, :medical_program).id,
      }

      conn = post conn, program_medication_path(conn, :create), params
      [error] = json_response(conn, 422)["error"]["invalid"]
      assert "$.medication_id" == error["entry"]
    end

    test "renders errors when medical program does not exists", %{conn: conn} do
      params = %{
        reimbursement: build(:reimbursement),
        medication_id: insert(:prm, :medication).id,
        medical_program_id: UUID.generate()
      }
      conn = post conn, program_medication_path(conn, :create), params
      [error] = json_response(conn, 422)["error"]["invalid"]
      assert "$.medical_program_id" == error["entry"]
    end

    test "renders errors when medical program not active", %{conn: conn} do
      params = %{
        reimbursement: build(:reimbursement),
        medication_id: insert(:prm, :medication).id,
        medical_program_id: insert(:prm, :medical_program, is_active: false).id,
      }

      conn = post conn, program_medication_path(conn, :create), params
      [error] = json_response(conn, 422)["error"]["invalid"]
      assert "$.medical_program_id" == error["entry"]
    end
  end

  describe "update program_medication" do
    setup [:create_program_medication]

    test "data is valid", %{conn: conn, program_medication: %ProgramMedication{id: id} = program_medication} do
      conn = put conn, program_medication_path(conn, :update, program_medication), medication_request_allowed: false
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, program_medication_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert_program_medication_response(resp)
      assert id == resp["data"]["id"]
      refute resp["medication_request_allowed"]
    end

    test "renders errors when data is invalid", %{conn: conn, program_medication: program_medication} do
      conn = put conn, program_medication_path(conn, :update, program_medication), reimbursement: true
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "cannot deactivate when medication_request_allowed is active", %{conn: conn, program_medication: pm} do
      conn = put conn, program_medication_path(conn, :update, pm), is_active: false
      [error] = json_response(conn, 422)["error"]["invalid"]
      assert "$.is_active" == error["entry"]
    end

    test "cannot allow medication_request when program_medication inactive", %{conn: conn} do
      pm = insert(:prm, :program_medication, is_active: false, medication_request_allowed: false)
      conn = put conn, program_medication_path(conn, :update, pm), medication_request_allowed: true

      [error] = json_response(conn, 422)["error"]["invalid"]
      assert "$.medication_request_allowed" == error["entry"]
    end
  end

  defp create_program_medication(_) do
    program_medication = fixture(:program_medication)
    {:ok, program_medication: program_medication}
  end

  def fixture(:program_medication) do
    insert(:prm, :program_medication)
  end

  defp assert_program_medication_response(response) do
    schema =
      "specs/json_schemas/program_medication/program_medication_response.json"
      |> File.read!()
      |> Poison.decode!()

    assert :ok == NExJsonSchema.Validator.validate(schema, response)
  end
end
