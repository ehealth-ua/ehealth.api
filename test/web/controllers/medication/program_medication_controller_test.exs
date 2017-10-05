defmodule EHealthWeb.ProgramMedicationControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  alias Ecto.UUID
  alias EHealth.PRM.Medications.Program.Schema, as: ProgramMedication

  describe "index" do
    test "empty program_medications list", %{conn: conn} do
      conn = get conn, program_medication_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create program_medication" do
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

      assert_medication_program_response(resp)
      assert id == resp["data"]["id"]
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

      assert_medication_program_response(resp)
      assert id == resp["data"]["id"]
      refute resp["medication_request_allowed"]
    end

    test "renders errors when data is invalid", %{conn: conn, program_medication: program_medication} do
      conn = put conn, program_medication_path(conn, :update, program_medication), reimbursement: true
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  defp create_program_medication(_) do
    program_medication = fixture(:program_medication)
    {:ok, program_medication: program_medication}
  end

  def fixture(:program_medication) do
    insert(:prm, :program_medication)
  end

  defp assert_medication_program_response(response) do
    schema =
      "specs/json_schemas/program_medications_response.json"
      |> File.read!()
      |> Poison.decode!()

    assert :ok == NExJsonSchema.Validator.validate(schema, response)
  end
end
