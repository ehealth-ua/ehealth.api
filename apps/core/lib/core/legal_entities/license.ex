defmodule Core.LegalEntities.License do
  @moduledoc false

  use Ecto.Schema
  alias Core.LegalEntities.LegalEntity
  alias Ecto.UUID
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__, :edr_data, :legal_entities]}

  @fields_required ~w(
    id
    is_active
    type
    issued_by
    issued_date
    active_from_date
    order_no
    inserted_by
    updated_by
  )a

  @fields_optional ~w(
    license_number
    issuer_status
    expiry_date
    what_licensed
  )a

  @type_msp "MSP"
  @type_pharmacy "PHARMACY"

  def type(:msp), do: @type_msp
  def type(:pharmacy), do: @type_pharmacy

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "licenses" do
    field(:is_active, :boolean, default: true)
    field(:license_number, :string)
    field(:type, :string)
    field(:issued_by, :string)
    field(:issued_date, :date)
    field(:issuer_status, :string)
    field(:expiry_date, :date)
    field(:active_from_date, :date)
    field(:what_licensed, :string)
    field(:order_no, :string)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    has_many(:legal_entities, LegalEntity)
    has_many(:edr_data, through: [:legal_entities, :edr_data])

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = entity, params) do
    entity
    |> cast(params, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end
