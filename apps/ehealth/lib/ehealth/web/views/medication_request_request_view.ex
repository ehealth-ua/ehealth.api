defmodule EHealth.Web.MedicationRequestRequestView do
  @moduledoc false
  use EHealth.Web, :view
  alias EHealth.Web.{PersonView, EmployeeView, LegalEntityView, DivisionView, MedicalProgramView, INNMDosageView}

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
    values.medication_request_request.data
    |> Map.take(~w(created_at started_at ended_at dispense_valid_from dispense_valid_to)a)
    |> Map.put(:id, values.medication_request_request.id)
    |> Map.put(:person, render_person(values.person, values.medication_request_request.data.created_at))
    |> Map.put(:employee, render(EmployeeView, "employee_private.json", %{employee: values.employee}))
    |> Map.put(
      :legal_entity,
      render(LegalEntityView, "show_reimbursement.json", %{legal_entity: values.legal_entity})
    )
    |> Map.put(:division, render(DivisionView, "division.json", %{division: values.division}))
    |> Map.put(
      :medication_info,
      render(INNMDosageView, "innm_dosage_short.json", %{
        innm_dosage: values.medication,
        medication_qty: values.medication_request_request.data.medication_qty
      })
    )
    |> Map.put(:medical_program, render(MedicalProgramView, "show.json", %{medical_program: values.medical_program}))
    |> Map.put(:request_number, values.medication_request_request.request_number)
    |> Map.put(:status, values.medication_request_request.status)
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
      rejection_reason: "",
      participants: render(__MODULE__, "participants.json", %{participants: program.participants})
    }
  end

  def render("participants.json", %{participants: participants}) do
    render_many(participants, __MODULE__, "participant.json", as: :participant)
  end

  def render("participant.json", %{participant: participant}) do
    %{
      medication_id: participant.id,
      medication_name: participant.name,
      form: participant.form,
      manufacturer: participant.manufacturer,
      reimbursement_amount: participant["reimbursement_amount"]
    }
  end

  def render_person(%{"birth_date" => birth_date} = person, mrr_created_at) do
    age = get_age(birth_date, mrr_created_at)

    PersonView
    |> render("show.json", %{"person" => person})
    |> Map.put("age", age)
    |> Map.drop(["birth_date", "addresses"])
  end

  defp get_age(birth_date, current_date) do
    Timex.diff(current_date, Timex.parse!(birth_date, "{YYYY}-{0M}-{D}"), :years)
  end
end
