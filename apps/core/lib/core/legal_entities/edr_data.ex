defmodule Core.LegalEntities.EdrData do
  @moduledoc false

  use Ecto.Schema
  alias Core.LegalEntities.LegalEntity
  alias Ecto.UUID
  import Ecto.Changeset

  @required_fields ~w(
    edr_id
    name
    public_name
    edrpou
    kveds
    registration_address
    is_active
    state
    inserted_by
    updated_by
  )a

  @optional_fields ~w(id short_name legal_form)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "edr_data" do
    field(:edr_id, :integer)
    field(:name, :string)
    field(:short_name, :string)
    field(:public_name, :string)
    field(:state, :integer)
    field(:legal_form, :string)
    field(:edrpou, :string)
    field(:kveds, {:array, :map})
    field(:registration_address, :map)
    field(:is_active, :boolean, default: true)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    has_many(:legal_entities, LegalEntity, foreign_key: :edr_data_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = entity, params) do
    entity
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
