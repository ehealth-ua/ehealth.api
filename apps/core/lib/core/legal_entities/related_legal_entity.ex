defmodule Core.LegalEntities.RelatedLegalEntity do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Core.LegalEntities.LegalEntity

  @derive {Jason.Encoder, except: [:__meta__]}

  @required_fields ~w(merged_from_id merged_to_id reason is_active inserted_by)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "related_legal_entities" do
    field(:reason, :string)
    field(:is_active, :boolean, default: false)
    field(:inserted_by, Ecto.UUID)

    belongs_to(:merged_from, LegalEntity, type: Ecto.UUID)
    belongs_to(:merged_to, LegalEntity, type: Ecto.UUID)

    timestamps(updated_at: false)
  end

  def changeset(%__MODULE__{} = entity, attrs) do
    entity
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
