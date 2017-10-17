defmodule EHealth.Web.MedicationRequestRequestView do
  @moduledoc false
  use EHealth.Web, :view
  alias EHealth.Web.MedicationRequestRequestView

  def render("index.json", %{medication_request_requests: medication_request_requests}) do
    render_many(medication_request_requests, MedicationRequestRequestView, "medication_request_request.json")
  end

  def render("show.json", %{medication_request_request: medication_request_request}) do
    render_one(medication_request_request, MedicationRequestRequestView, "medication_request_request.json")
  end

  def render("medication_request_request.json", %{medication_request_request: medication_request_request}) do
    %{id: medication_request_request.id,
      data: medication_request_request.data,
      number: medication_request_request.number,
      status: medication_request_request.status,
      inserted_by: medication_request_request.inserted_by,
      updated_by: medication_request_request.updated_by}
  end

  def render("show_prequalify_programs.json", %{programs: programs}) do
    render_many(programs, MedicationRequestRequestView, "show_prequalify_program.json", as: :program)
  end
  def render("show_prequalify_program.json", %{program: program}) do
    maybe_add_error_reason(
      %{program_id: program.medical_program_id,
        program_name: program.medical_program_name,
        status: program.status
      }
    )
  end

  defp maybe_add_error_reason(%{status: "INVALID"} = program) do
    Map.put(program, :invalid_reason, "Innm not on the list of approved innms for program \"#{program.program_name}\"")
  end
  defp maybe_add_error_reason(program), do: program
end
