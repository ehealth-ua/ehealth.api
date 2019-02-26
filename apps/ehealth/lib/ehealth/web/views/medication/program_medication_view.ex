defmodule EHealth.Web.ProgramMedicationView do
  @moduledoc false

  use EHealth.Web, :view

  alias EHealth.Web.MedicalProgramView
  alias EHealth.Web.MedicationView

  @program_medication_view_fields [
    :id,
    :medication_request_allowed,
    :is_active,
    :wholesale_price,
    :consumer_price,
    :reimbursement_daily_dosage,
    :estimated_payment_amount,
    :updated_by,
    :inserted_by,
    :inserted_at,
    :updated_at
  ]

  def render("index.json", %{program_medications: program_medications}) do
    render_many(program_medications, __MODULE__, "program_medication.json")
  end

  def render("show.json", %{program_medication: program_medication}) do
    render_one(program_medication, __MODULE__, "program_medication.json")
  end

  def render("program_medication.json", %{program_medication: program_medication}) do
    program_medication
    |> Map.take(@program_medication_view_fields)
    |> Map.merge(%{
      reimbursement: Map.take(program_medication.reimbursement, [:type, :reimbursement_amount]),
      medication: render_one(program_medication.medication, MedicationView, "medication.json"),
      medical_program: render_one(program_medication.medical_program, MedicalProgramView, "show.json")
    })
  end
end
