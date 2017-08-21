defmodule EHealth.PRM.Employees.Schema do
  @moduledoc false

  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.Divisions.Schema, as: Division
  alias EHealth.PRM.Parties.Schema, as: Party

  use Ecto.Schema

  @employee_type_owner "OWNER"
  @employee_type_doctor "DOCTOR"

  def employee_type(:owner), do: @employee_type_owner
  def employee_type(:doctor), do: @employee_type_doctor

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
    field :additional_info, :map

    belongs_to :party, Party, type: Ecto.UUID
    belongs_to :division, Division, type: Ecto.UUID
    belongs_to :legal_entity, LegalEntity, type: Ecto.UUID

    timestamps()
  end
end
