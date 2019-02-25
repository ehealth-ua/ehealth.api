defmodule GraphQLWeb.ProgramMedicationResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

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
