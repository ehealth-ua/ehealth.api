defmodule Core.Medications.Program do
  @moduledoc false

  use Ecto.Schema

  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Medications.Medication
  alias Core.Medications.Program.Reimbursement

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts type: :utc_datetime
  schema "program_medications" do
    field(:medication_request_allowed, :boolean, default: true)
    field(:is_active, :boolean, default: true)
    field(:wholesale_price, :float)
    field(:consumer_price, :float)
    field(:reimbursement_daily_dosage, :float)
    field(:estimated_payment_amount, :float)
    field(:inserted_by, Ecto.UUID)
    field(:updated_by, Ecto.UUID)

    embeds_one(:reimbursement, Reimbursement, on_replace: :update)

    belongs_to(:medication, Medication, type: Ecto.UUID)
    belongs_to(:medical_program, MedicalProgram, type: Ecto.UUID)
    has_many(:innm_dosages, through: [:medication, :innm_dosages])

    timestamps(type: :utc_datetime)
  end
end
