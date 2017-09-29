defmodule EHealth.Web.MedicationRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.LegalEntityView
  alias EHealth.Web.EmployeeView
  alias EHealth.Web.DivisionView
  alias EHealth.Web.MedicalProgramView
  alias EHealth.Web.PersonView

  def render("show.json", %{medication_request: medication_request}) do
    medication_request
    |> Map.take(~w(
      id
      status
      request_number
      created_at
      started_at
      ended_at
      dispense_valid_from
      dispense_valid_to
    ))
    |> Map.put("legal_entity", render_one(medication_request["legal_entity"], LegalEntityView, "show.json"))
    |> Map.put("employee", render_one(medication_request["employee"], EmployeeView, "employee.json"))
    |> Map.put("division", render_one(medication_request["division"], DivisionView, "show.json"))
    |> Map.put("medical_program", render_one(medication_request["medical_program"], MedicalProgramView, "show.json"))
    |> Map.put("medication_info", render_one(medication_request, __MODULE__, "medication_info.json"))
    |> Map.put("person", render_one(medication_request["person"], PersonView, "show.json"))
  end

  def render("medication_info.json", %{medication_request: medication_request}) do
    medication = medication_request["medication"]
    ingredient = Enum.find(medication.ingredients, &(Map.get(&1, :is_primary)))
    dosage_ingredient = Enum.find(ingredient.innm_dosage.ingredients, &(Map.get(&1, :is_primary)))

    medication_request
    |> Map.take(~w(medication_qty))
    |> Map.put("container", medication.container)
    |> Map.put("form", medication.form)
    |> Map.put("medication_id", medication.id)
    |> Map.put("innm_dosage", dosage_ingredient.innm)
    |> Map.put("dosage", ingredient.dosage)
  end
end
