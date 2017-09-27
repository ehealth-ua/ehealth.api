defmodule EHealth.PRM.Medications.Medication.Ingredient do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    dosage
    medication_child_id
    is_primary
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "ingredients" do
    field :dosage, :map
    field :is_primary, :boolean, default: false

    belongs_to :medication, EHealth.PRM.Medications.Medication.Schema, [type: Ecto.UUID, foreign_key: :parent_id]
    belongs_to :innm_dosage,
               EHealth.PRM.Medications.INNMDosage.Schema,
               [type: Ecto.UUID, foreign_key: :medication_child_id]

    timestamps()
  end

  def changeset(%EHealth.PRM.Medications.Medication.Ingredient{} = ingredient, attrs) do
    attrs = Map.put(attrs, "medication_child_id", attrs["id"])
    ingredient
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:medication_child_id)
    |> foreign_key_constraint(:parent_id)
  end
end
