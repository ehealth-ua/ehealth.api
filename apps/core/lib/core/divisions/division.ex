defmodule Core.Divisions.Division do
  @moduledoc false

  use Ecto.Schema

  alias Core.Divisions.DivisionAddress
  alias Core.LegalEntities.LegalEntity

  @derive {Jason.Encoder, except: [:__meta__]}

  @status_active "ACTIVE"
  @status_inactive "INACTIVE"

  @type_clinic "CLINIC"
  @type_ambulant_clinic "AMBULANT_CLINIC"
  @type_fap "FAP"
  @type_drugstore "DRUGSTORE"
  @type_drugstore_point "DRUGSTORE_POINT"

  def status(:active), do: @status_active
  def status(:inactive), do: @status_inactive

  def type(:clinic), do: @type_clinic
  def type(:ambulant_clinic), do: @type_ambulant_clinic
  def type(:fap), do: @type_fap
  def type(:drugstore), do: @type_drugstore
  def type(:drugstore_point), do: @type_drugstore_point

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
    field(:location, Geo.PostGIS.Geometry)
    field(:working_hours, :map)
    field(:dls_id, :string)
    field(:dls_verified, :boolean)

    belongs_to(:legal_entity, LegalEntity, type: Ecto.UUID)
    has_many(:addresses, DivisionAddress, foreign_key: :division_id, on_replace: :delete)

    timestamps(type: :utc_datetime_usec)
  end
end
