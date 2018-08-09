defmodule EHealth.Divisions.Division do
  @moduledoc false

  use Ecto.Schema
  alias EHealth.Divisions.DivisionAddress
  alias EHealth.LegalEntities.LegalEntity

  @derive {Jason.Encoder, except: [:__meta__]}

  @status_active "ACTIVE"
  @status_inactive "INACTIVE"

  @type_clinic "CLINIC"
  @type_ambulant_clinic "AMBULANT_CLINIC"
  @type_fap "FAP"

  def status(:active), do: @status_active
  def status(:inactive), do: @status_inactive

  def type(:clinic), do: @type_clinic
  def type(:ambulant_clinic), do: @type_ambulant_clinic
  def type(:fap), do: @type_fap

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "divisions" do
    field(:email, :string)
    field(:external_id, :string)
    field(:mountain_group, :boolean, null: false)
    field(:name, :string)
    field(:phones, {:array, :map})
    field(:type, :string)
    field(:status, :string, null: false)
    field(:is_active, :boolean, default: false)
    field(:location, Geo.Geometry)
    field(:working_hours, :map)

    belongs_to(:legal_entity, LegalEntity, type: Ecto.UUID)
    has_many(:addresses, DivisionAddress, foreign_key: :division_id, on_replace: :delete)

    timestamps()
  end
end
