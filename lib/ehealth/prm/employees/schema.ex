defmodule EHealth.PRM.Employees.Schema do
  @moduledoc false

  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.Divisions.Schema, as: Division
  alias EHealth.PRM.Parties.Schema, as: Party

  use Ecto.Schema

  @type_owner "OWNER"
  @type_doctor "DOCTOR"
  @type_pharmacy_owner "PHARMACY_OWNER"

  @status_dismissed "DISMISSED"
  @status_approved "APPROVED"

  def type(:owner), do: @type_owner
  def type(:doctor), do: @type_doctor
  def type(:pharmacy_owner), do: @type_pharmacy_owner

  def status(:dismissed), do: @status_dismissed
  def status(:approved), do: @status_approved

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
