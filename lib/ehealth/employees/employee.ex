defmodule EHealth.Employees.Employee do
  @moduledoc false

  use Ecto.Schema

  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Divisions.Division
  alias EHealth.Parties.Party

  @type_owner "OWNER"
  @type_doctor "DOCTOR"
  @type_pharmacy_owner "PHARMACY_OWNER"
  @type_pharmacist "PHARMACIST"

  @status_new "NEW"
  @status_approved "APPROVED"
  @status_dismissed "DISMISSED"

  def type(:owner), do: @type_owner
  def type(:doctor), do: @type_doctor
  def type(:pharmacy_owner), do: @type_pharmacy_owner
  def type(:pharmacist), do: @type_pharmacist

  def status(:new), do: @status_new
  def status(:approved), do: @status_approved
  def status(:dismissed), do: @status_dismissed

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
