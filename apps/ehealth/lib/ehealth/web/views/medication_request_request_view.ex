defmodule EHealth.Web.MedicationRequestRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias Core.MedicationRequestRequest.Renderer, as: MedicationRequestRequestRenderer
  alias EHealth.Web.DivisionView
  alias EHealth.Web.EmployeeView
  alias EHealth.Web.INNMDosageView
  alias EHealth.Web.LegalEntityView
  alias EHealth.Web.MedicalProgramView

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
    optional_fields = ~w(context dosage_instruction)a

    values.medication_request_request.data
    |> Map.take(~w(
      created_at
      started_at
      ended_at
      dispense_valid_from
      dispense_valid_to
      intent
      category
    )a)
    |> Map.merge(%{
      id: values.medication_request_request.id,
      person: render_person(values.person, values.medication_request_request.data.created_at),
      employee: render(EmployeeView, "employee_private.json", %{employee: values.employee}),
      legal_entity: render(LegalEntityView, "show_reimbursement.json", %{legal_entity: values.legal_entity}),
      division: render(DivisionView, "division.json", %{division: values.division}),
      medication_info:
        render(INNMDosageView, "innm_dosage_short.json", %{
          innm_dosage: values.medication,
          medication_qty: values.medication_request_request.data.medication_qty
        }),
      medical_program: render(MedicalProgramView, "show.json", %{medical_program: values.medical_program}),
      request_number: values.medication_request_request.request_number,
      status: values.medication_request_request.status
    })
    |> put_optional_fields(values.medication_request_request.data, optional_fields)
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

  defp put_optional_fields(response, data, optional_fields) do
    optional_response =
      Enum.reduce(optional_fields, %{}, fn field, acc ->
        if Map.get(data, field), do: Map.put(acc, field, Map.get(data, field)), else: acc
      end)

    Map.merge(response, optional_response)
  end
end
