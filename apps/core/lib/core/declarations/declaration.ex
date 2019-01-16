defmodule Core.Declarations.Declaration do
  @moduledoc false

  use Ecto.Schema

  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Ecto.UUID

  embedded_schema do
    field(:person_id, UUID)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:status, :string)
    field(:signed_at, :utc_datetime)
    field(:created_by, UUID)
    field(:updated_by, UUID)
    field(:is_active, :boolean, default: false)
    field(:scope, :string)
    field(:declaration_request_id, UUID)
    field(:seed, :string)
    field(:reason, :string)
    field(:reason_description, :string)
    field(:overlimit, :boolean, default: false)
    field(:declaration_number, :string)

    timestamps(type: :utc_datetime)

    belongs_to(:legal_entity, LegalEntity, type: UUID)
    belongs_to(:division, Division, type: UUID)
    belongs_to(:employee, Employee, type: UUID)
  end
end
