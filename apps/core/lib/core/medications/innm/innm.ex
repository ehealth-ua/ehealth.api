defmodule Core.Medications.INNM do
  @moduledoc false
  use Ecto.Schema

  alias Core.Medications.INNMDosage.Ingredient

  @derive {Jason.Encoder, except: [:__meta__, :ingredients]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "innms" do
    field(:sctid, :string)
    field(:name, :string)
    field(:name_original, :string)
    field(:is_active, :boolean, default: true)
    field(:inserted_by, Ecto.UUID)
    field(:updated_by, Ecto.UUID)

    has_many(:ingredients, Ingredient, foreign_key: :innm_child_id)

    timestamps(type: :utc_datetime)
  end
end
