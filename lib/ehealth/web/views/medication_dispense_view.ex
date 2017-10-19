defmodule EHealth.Web.MedicationDispenseView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.LegalEntityView
  alias EHealth.Web.DivisionView
  alias EHealth.Web.MedicalProgramView
  alias EHealth.Web.MedicationRequestView
  alias EHealth.Web.PartyView

  def render("index.json", %{medication_dispenses: medication_dispenses, references: references}) do
    Enum.map(medication_dispenses, fn medication_dispense ->
      render_one(medication_dispense, __MODULE__, "show.json", %{
        medication_dispense: medication_dispense,
        references: %{
          party: Map.get(references.parties, medication_dispense["party_id"]),
          legal_entity: Map.get(references.legal_entities, medication_dispense["legal_entity_id"]),
          division: Map.get(references.divisions, medication_dispense["division_id"]),
          medication_request: Map.get(medication_dispense, "medication_request"),
          medical_program: Map.get(references.medical_programs, medication_dispense["medical_program_id"])
        }
      })
    end)
  end

  def render("show.json", %{medication_dispense: medication_dispense, references: references}) do
    party = Map.get(references, :party)
    party = if party, do: render_one(party, PartyView, "show.json"), else: %{}
    legal_entity = Map.get(references, :legal_entity)
    legal_entity = if legal_entity, do: render(LegalEntityView, "show_reimbursement.json", references), else: %{}
    division = Map.get(references, :division)
    division = if division, do: render(DivisionView, "show.json", references), else: %{}
    medical_program = Map.get(references, :medical_program)
    medical_program = if medical_program, do: render(MedicalProgramView, "show.json", references), else: %{}
    medication_dispense
    |> Map.take(~w(
      id
      dispensed_at
      status
      inserted_at
      inserted_by
      updated_at
      updated_by
      dispense_details
      payment_id
      details
    ))
    |> Map.put("medication_request", render_one(references.medication_request, MedicationRequestView, "show.json"))
    |> Map.put("party", party)
    |> Map.put("legal_entity", legal_entity)
    |> Map.put("division", division)
    |> Map.put("medical_program", medical_program)
  end
end
