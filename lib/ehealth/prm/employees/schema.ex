defmodule EHealth.PRM.Employees.Schema do
  @moduledoc false

  alias EHealth.PRM.EmployeeDoctors.Schema, as: EmployeeDoctor
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.Divisions.Schema, as: Division
  alias EHealth.PRM.EmployeeDoctors.Schema, as: EmployeeDoctor
  alias EHealth.PRM.Parties.Schema, as: Party

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "employees" do
    field :employee_type, :string
    field :is_active, :boolean, default: false
    field :position, :string
    field :start_date, :date
    field :end_date, :date
    field :status, :string
    field :status_reason, :string
    field :updated_by, Ecto.UUID
    field :inserted_by, Ecto.UUID

    belongs_to :party, Party, type: Ecto.UUID
    belongs_to :division, Division, type: Ecto.UUID
    belongs_to :legal_entity, LegalEntity, type: Ecto.UUID

    has_one :doctor, EmployeeDoctor, foreign_key: :employee_id

    timestamps()
  end
end
