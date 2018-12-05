defmodule EHealth.Web.MedicationRequestRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias Core.MedicationRequestRequest.Renderer, as: MedicationRequestRequestRenderer

  def render("index.json", %{medication_request_requests: medication_request_requests}) do
    render_many(
      medication_request_requests,
      __MODULE__,
      "medication_request_request_detail.json",
      as: :data
    )
  end

  def render("show.json", %{medication_request_request: medication_request_request}) do
    render_one(medication_request_request, __MODULE__, "medication_request_request.json")
  end

  def render("medication_request_request_detail.json", %{data: values}) do
    MedicationRequestRequestRenderer.render("medication_request_request_detail.json", values)
  end

  def render("medication_request_request.json", %{medication_request_request: medication_request_request}) do
    %{
      id: medication_request_request.id,
      data: medication_request_request.data,
      number: medication_request_request.request_number,
      status: medication_request_request.status,
      inserted_by: medication_request_request.inserted_by,
      updated_by: medication_request_request.updated_by
    }
  end

  def render("show_prequalify_programs.json", %{programs: programs}) do
    render_many(programs, __MODULE__, "show_prequalify_program.json", as: :program)
  end

  def render("show_prequalify_program.json", %{program: %{status: "INVALID"} = program}) do
    %{
      program_id: program.id,
      program_name: program.name,
      status: program.status,
      rejection_reason: program.rejection_reason
    }
  end

  def render("show_prequalify_program.json", %{program: %{status: "VALID"} = program}) do
    %{
      program_id: program.id,
      program_name: program.name,
      status: program.status,
      rejection_reason: ""
    }
  end

  def render_person(person, mrr_created_at) do
    MedicationRequestRequestRenderer.render_person(person, mrr_created_at)
  end
end
