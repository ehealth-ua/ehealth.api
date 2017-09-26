defmodule EHealth.PRM.Drugs.Medication.Ingredient do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    dosage
    innm_id
    is_active_substance
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "ingredients" do
    field :dosage, :map
    field :is_active_substance, :boolean, default: false

    belongs_to :innm, EHealth.PRM.Drugs.INNM.Schema, type: Ecto.UUID
    belongs_to :medication, EHealth.PRM.Drugs.Medication.Schema, type: Ecto.UUID

    timestamps()
  end

  def changeset(%EHealth.PRM.Drugs.Medication.Ingredient{} = ingredient, attrs) do
    attrs = Map.put(attrs, "innm_id", attrs["id"])
    ingredient
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:innm_id)
    |> foreign_key_constraint(:medication_id)
  end
end
