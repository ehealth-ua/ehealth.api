defmodule EHealth.Medications.INNMDosage.Ingredient do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  alias EHealth.Medications.INNM
  alias EHealth.Medications.INNMDosage

  @fields ~w(
    dosage
    innm_child_id
    is_primary
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "ingredients" do
    field :dosage, :map
    field :is_primary, :boolean, default: false

    belongs_to :innm_dosage, INNMDosage, [type: Ecto.UUID, foreign_key: :parent_id]
    belongs_to :innm, INNM, [type: Ecto.UUID, foreign_key: :innm_child_id]

    timestamps()
  end

  def changeset(%EHealth.Medications.INNMDosage.Ingredient{} = ingredient, attrs) do
    attrs = Map.put(attrs, "innm_child_id", attrs["id"])
    ingredient
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:innm_child_id)
    |> foreign_key_constraint(:parent_id)
  end
end
