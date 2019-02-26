defmodule EHealth.Web.MedicationRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias Core.MedicationRequests.Renderer, as: MedicationRequestsRenderer

  def render("index.json", %{medication_requests: medication_requests}) do
    render_many(medication_requests, __MODULE__, "show.json")
  end

  def render("show.json", %{medication_request: medication_request}) do
    MedicationRequestsRenderer.render("show.json", medication_request)
  end

  def render("qualify.json", %{medical_programs: medical_programs, validations: validations}) do
    Enum.map(medical_programs, fn program ->
      {_, validation} = Enum.find(validations, fn {id, _} -> id == program.id end)

      {status, reason, participants} =
        case validation do
          :ok ->
            {"VALID", "",
             render_many(
               program.program_medications,
               __MODULE__,
               "program_medication.json",
               as: :program_medication
             )}

          {:error, reason} ->
            {"INVALID", reason, []}
        end

      %{
        "program_id" => program.id,
        "program_name" => program.name,
        "status" => status,
        "rejection_reason" => reason,
        "participants" => participants
      }
    end)
  end

  def render("program_medication.json", %{program_medication: program_medication}) do
    medication = program_medication.medication

    %{
      "medication_id" => medication.id,
      "medication_name" => medication.name,
      "form" => medication.form,
      "manufacturer" => medication.manufacturer,
      "package_qty" => medication.package_qty,
      "package_min_qty" => medication.package_min_qty,
      "reimbursement_amount" => program_medication.reimbursement.reimbursement_amount
    }
  end
end
