defmodule GraphQL.ProgramMedicationResolverTest do
  @moduledoc false

  use GraphQL.ConnCase, async: true

  import Core.Factories

  alias Absinthe.Relay.Node
  alias Core.Medications.Program, as: ProgramMedication
  alias Core.PRMRepo
  alias Ecto.UUID

  @fields """
    id
    databaseId
    medicationRequestAllowed
    isActive
    wholesalePrice
    consumerPrice
    reimbursementDailyDosage
    estimatedPaymentAmount
    insertedAt
    updatedAt
    reimbursement {
      type
      reimbursementAmount
    }
    medicalProgram {
      databaseId
      name
      isActive
      insertedAt
      updatedAt
    }
    medication {
      name
      form
      packageQty
      packageMinQty
      certificate
      certificateExpiredAt
      isActive
      type
      container {
        numeratorUnit
        numeratorValue
        denumeratorUnit
        denumeratorValue
      }
    }
  """

  @program_medications_query """
    query ProgramMedicationsQuery($filter: ProgramMedicationFilter, $orderBy: ProgramMedicationOrderBy) {
      programMedications(first: 10, filter: $filter, orderBy: $orderBy) {
        nodes {
          #{@fields}
        }
      }
    }
  """

  @program_medication_by_id_query """
    query GetProgramMedicationByIdQuery($id: ID) {
      programMedication(id: $id) {
        #{@fields}
      }
    }
  """

  @program_medication_create_query """
    mutation CreateProgramMedication($input: CreateProgramMedicationInput!) {
      createProgramMedication(input: $input) {
        programMedication {
          #{@fields}
        }
      }
    }
  """

  describe "create" do
    test "success", %{conn: conn} do
      %{id: medication_id} = insert(:prm, :medication)
      %{id: medical_program_id} = insert(:prm, :medical_program)

      variables = program_medication_input(medication_id, medical_program_id)
      consumer_id = UUID.generate()

      resp_body =
        conn
        |> put_scope("program_medication:write")
        |> put_consumer_id(consumer_id)
        |> post_query(@program_medication_create_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data createProgramMedication programMedication))
      refute resp_body["errors"]

      entity = PRMRepo.get(ProgramMedication, resp_entity["databaseId"])
      assert consumer_id == entity.inserted_by
    end

    test "scope not allowed", %{conn: conn} do
      variables = program_medication_input()

      resp_body =
        conn
        |> post_query(@program_medication_create_query, variables)
        |> json_response(200)

      refute get_in(resp_body, ~w(data createProgramMedication programMedication))

      assert %{"errors" => [error]} = resp_body
      assert "FORBIDDEN" == error["extensions"]["code"]
      assert Map.has_key?(error["extensions"]["exception"], "missingAllowances")
    end
  end

  describe "list" do
    test "success", %{conn: conn} do
      gen_innm_dosage = &insert(:prm, :innm_dosage, name: &1).id
      gen_medical_program = &insert(:prm, :medical_program, name: &1, is_active: true).id

      gen_medication =
        &insert(:prm, :medication,
          name: &1,
          is_active: true,
          form: "COATED_TABLET",
          manufacturer: build(:manufacturer, name: "Kyiv Vitamin Plant")
        ).id

      for i <- 1..3 do
        medication_id = gen_medication.("Lorem medication #{i}")
        medication2_id = gen_medication.("Next medication #{i}")
        innm_dosage_id = gen_innm_dosage.("Dosage #{i}")
        innm_dosage2_id = insert(:prm, :innm_dosage, name: "Dosage #{i}", is_active: false).id

        insert(:prm, :ingredient_medication, parent_id: medication_id, medication_child_id: innm_dosage_id)
        insert(:prm, :ingredient_medication, parent_id: medication2_id, medication_child_id: innm_dosage2_id)

        insert(:prm, :program_medication,
          medication_id: medication_id,
          medical_program_id: gen_medical_program.("Acme medical program #{i}")
        )

        insert(:prm, :program_medication,
          medication_id: medication2_id,
          medical_program_id: gen_medical_program.("Next Acme medical program #{i}")
        )
      end

      insert_list(6, :prm, :program_medication, is_active: false)
      insert_list(9, :prm, :program_medication, medication_request_allowed: false)

      variables = %{
        filter: %{
          is_active: true,
          medication_request_allowed: true,
          medical_program: %{
            is_active: true,
            name: "Acme"
          },
          medication: %{
            name: "medication",
            is_active: true,
            form: "COATED_TABLET",
            innm_dosages: %{
              name: "Dosage 1",
              is_active: true
            }
          }
        }
      }

      resp_body =
        conn
        |> put_scope("program_medication:read")
        |> post_query(@program_medications_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data programMedications nodes))
      refute resp_body["errors"]

      assert 1 == length(resp_entities)
    end
  end

  describe "get by id" do
    test "success", %{conn: conn} do
      %{id: id} = insert(:prm, :program_medication, is_active: true)
      variables = %{id: Node.to_global_id("ProgramMedication", id)}

      resp_body =
        conn
        |> put_scope("program_medication:read")
        |> post_query(@program_medication_by_id_query, variables)
        |> json_response(200)

      refute resp_body["errors"]
      assert get_in(resp_body, ~w(data programMedication))
    end

    test "not found", %{conn: conn} do
      variables = %{id: Node.to_global_id("ProgramMedication", UUID.generate())}

      resp_body =
        conn
        |> put_scope("program_medication:read")
        |> post_query(@program_medication_by_id_query, variables)
        |> json_response(200)

      [error] = resp_body["errors"]

      refute get_in(resp_body, ~w(data programMedication))
      assert "NOT_FOUND" == error["extensions"]["code"]
    end
  end

  defp program_medication_input(medication_id \\ UUID.generate(), medical_program_id \\ UUID.generate()) do
    %{
      input: %{
        medication_id: Node.to_global_id("Medication", medication_id),
        medical_program_id: Node.to_global_id("MedicalProgram", medical_program_id),
        reimbursement: %{type: "FIXED", reimbursement_amount: 12},
        wholesale_price: 100.0,
        consumer_price: 200.0,
        reimbursement_daily_dosage: 10,
        estimated_payment_amount: 20
      }
    }
  end
end
