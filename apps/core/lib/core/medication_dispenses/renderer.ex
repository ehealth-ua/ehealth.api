defmodule Core.MedicationDispense.Renderer do
  @moduledoc false

  alias Core.Divisions.Renderer, as: DivisionsRenderer
  alias Core.LegalEntities.Renderer, as: LegalEntitiesRenderer
  alias Core.MedicalPrograms.Renderer, as: MedicalProgramsRenderer
  alias Core.MedicationRequests.Renderer, as: MedicationRequestsRenderer
  alias Core.Parties.Renderer, as: PartiesRenderer

  def render("show.json", medication_dispense, references) do
    party = Map.get(references, :party)
    party = if party, do: PartiesRenderer.render("show.json", party), else: %{}

    legal_entity = Map.get(references, :legal_entity)
    legal_entity = if legal_entity, do: LegalEntitiesRenderer.render("show_reimbursement.json", legal_entity), else: %{}

    division = Map.get(references, :division)
    division = if division, do: DivisionsRenderer.render("division.json", division), else: %{}

    medical_program = Map.get(references, :medical_program)
    details = Map.get(medication_dispense, "details", [])

    response =
      medication_dispense
      |> Map.take(~w(
        id
        dispensed_at
        dispensed_by
        status
        inserted_at
        inserted_by
        updated_at
        updated_by
        dispense_details
        payment_id
        payment_amount
      ))
      |> Map.merge(%{
        "details" => render("details.json", details),
        "medication_request" => MedicationRequestsRenderer.render("show.json", references.medication_request),
        "party" => party,
        "legal_entity" => legal_entity,
        "division" => division
      })

    if medical_program do
      Map.put(response, "medical_program", MedicalProgramsRenderer.render("show.json", medical_program))
    else
      response
    end
  end

  def render("details.json", details) when is_list(details) do
    Enum.map(details, fn detail ->
      detail
      |> Map.take(~w(
        medication_qty
        sell_price
        sell_amount
        discount_amount
        reimbursement_amount
      ))
      |> Map.put("medication", render("medication.json", detail["medication"]))
    end)
  end

  def render("medication.json", %_{} = medication) do
    Map.take(medication, ~w(name type manufacturer form container)a)
  end

  def render("medication.json", %{} = medication) do
    Map.take(medication, ~w(name type manufacturer form container))
  end
end
