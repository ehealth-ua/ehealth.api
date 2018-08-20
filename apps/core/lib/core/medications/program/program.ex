defmodule Core.Medications.Program do
  @moduledoc false

  use Ecto.Schema
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Medications.Medication

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "program_medications" do
    field(:reimbursement, :map)
    field(:medication_request_allowed, :boolean, default: true)
    field(:is_active, :boolean, default: true)
    field(:inserted_by, Ecto.UUID)
    field(:updated_by, Ecto.UUID)

    belongs_to(:medication, Medication, type: Ecto.UUID)
    belongs_to(:medical_program, MedicalProgram, type: Ecto.UUID)

    timestamps()
  end
end
