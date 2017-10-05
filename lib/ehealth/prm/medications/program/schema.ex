defmodule EHealth.PRM.Medications.Program.Schema do
  @moduledoc false
  use Ecto.Schema
  alias EHealth.PRM.Medications.Medication.Schema, as: Medication
  alias EHealth.PRM.MedicalPrograms.Schema, as: MedicalProgram

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "program_medications" do
    field :reimbursement, :map
    field :medication_request_allowed, :boolean, default: false
    field :is_active, :boolean, default: true
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    belongs_to :medication, Medication, type: Ecto.UUID
    belongs_to :medical_program, MedicalProgram, type: Ecto.UUID

    timestamps()
  end
end
