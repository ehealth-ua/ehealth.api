defmodule EHealth.Web.MedicationDispenseView do
  @moduledoc false

  use EHealth.Web, :view
  alias Core.MedicationDispense.Renderer, as: MedicationDispenseRenderer

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
    MedicationDispenseRenderer.render("show.json", medication_dispense, references)
  end
end
