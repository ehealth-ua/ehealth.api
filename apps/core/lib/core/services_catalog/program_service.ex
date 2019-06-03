defmodule Core.Services.ProgramService do
  @moduledoc false

  use Ecto.Schema

  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Services.Service
  alias Core.Services.ServiceGroup
  alias Ecto.UUID

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "program_services" do
    field(:description, :string)
    field(:consumer_price, :float)
    field(:is_active, :boolean, default: true)
    field(:request_allowed, :boolean)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    belongs_to(:medical_program, MedicalProgram, type: UUID, foreign_key: :program_id)
    belongs_to(:service, Service, type: UUID)
    belongs_to(:service_group, ServiceGroup, type: UUID)

    timestamps(type: :utc_datetime_usec)
  end
end
