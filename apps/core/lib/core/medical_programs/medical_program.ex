defmodule Core.MedicalPrograms.MedicalProgram do
  @moduledoc false

  use Ecto.Schema

  alias Core.Medications.Program
  alias Core.Services.ProgramService

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medical_programs" do
    field(:name, :string)
    field(:type, :string)
    field(:is_active, :boolean, default: true)
    field(:inserted_by, Ecto.UUID)
    field(:updated_by, Ecto.UUID)

    has_one(:program_service, ProgramService, foreign_key: :program_id)
    has_many(:program_medications, Program)

    timestamps(type: :utc_datetime_usec)
  end
end
