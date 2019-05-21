defmodule Core.LegalEntities.SignedContent do
  @moduledoc false

  use Ecto.Schema
  alias Core.LegalEntities.LegalEntity
  alias Ecto.UUID
  import Ecto.Changeset

  @fields_required ~w(filename legal_entity_id)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "legal_entity_signed_contents" do
    field(:filename, :string)
    belongs_to(:legal_entity, LegalEntity, type: UUID)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(%__MODULE__{} = entity, params) do
    entity
    |> cast(params, @fields_required)
    |> validate_required(@fields_required)
  end
end
