defmodule EHealth.Web.MedicationRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.LegalEntityView
  alias EHealth.Web.EmployeeView
  alias EHealth.Web.DivisionView
  alias EHealth.Web.MedicalProgramView
  alias EHealth.Web.PersonView

  def render("index.json", %{medication_requests: medication_requests}) do
    render_many(medication_requests, __MODULE__, "show.json")
  end

  def render("show.json", %{medication_request: medication_request}) do
    legal_entity = medication_request["legal_entity"]
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
    |> Map.put("legal_entity", render_one(legal_entity, LegalEntityView, "show_reimbursement.json"))
    |> Map.put("employee", render_one(medication_request["employee"], EmployeeView, "employee.json"))
    |> Map.put("division", render_one(medication_request["division"], DivisionView, "show.json"))
    |> Map.put("medical_program", render_one(medication_request["medical_program"], MedicalProgramView, "show.json"))
    |> Map.put("medication_info", render_one(medication_request, __MODULE__, "medication_info.json"))
    |> Map.put("person", render_one(medication_request["person"], PersonView, "show.json"))
  end

  def render("medication_info.json", %{medication_request: medication_request}) do
    medication = medication_request["medication"]
    ingredient = Enum.find(medication.ingredients, &(Map.get(&1, :is_primary)))

    medication_request
    |> Map.take(~w(medication_qty))
    |> Map.put("form", medication.form)
    |> Map.put("medication_id", medication.id)
    |> Map.put("medication_name", medication.name)
    |> Map.put("dosage", ingredient.dosage)
  end

  def render("qualify.json", %{medical_programs: medical_programs, validations: validations}) do
    Enum.map(medical_programs, fn program ->
      {_, validation} = Enum.find(validations, fn {id, _} -> id == program.id end)
      {status, reason, participants} = case validation do
        :ok ->
          {"VALID", "", render_many(
            program.program_medications,
            __MODULE__,
            "program_medication.json",
            as: :program_medication
          )}
        {:error, reason} -> {"INVALID", reason, []}
      end

      %{
        "id" => program.id,
        "name" => program.name,
        "status" => status,
        "invalid_reason" => reason,
        "participants" => participants,
      }
    end)
  end

  def render("program_medication.json", %{program_medication: program_medication}) do
    program_medication.medication
    |> Map.take(~w(id name form manufacturer)a)
    |> Map.put("reimbursement_amount", program_medication.reimbursement["reimbursement_amount"])
  end
end
