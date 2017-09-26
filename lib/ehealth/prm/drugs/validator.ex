defmodule EHealth.PRM.Drugs.Validator do
  @moduledoc """
  Drugs validator.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias EHealth.PRMRepo
  alias EHealth.PRM.Drugs.Substance
  alias EHealth.PRM.Drugs.INNM.Schema, as: INNM
  alias EHealth.PRM.Drugs.Medication.Schema, as: Medication
  alias EHealth.PRM.Drugs.INNM.Ingredient, as: INNMIngredient
  alias EHealth.PRM.Drugs.Medication.Ingredient, as: MedicationIngredient

  @type_innm INNM.type()
  @type_medication Medication.type()

  def validate_ingredients(changeset) do
    changeset
    |> validate_ingredients_fk()
    |> validate_ingredients_id_uniqueness()
    |> validate_ingedients_active_substance_uniqueness()
  end

  defp validate_ingredients_fk(changeset) do
    validate_change changeset, :ingredients, fn :ingredients, ingredients ->
      ingredients
      |> Enum.map(&get_ingredient_id/1)
      |> Enum.uniq()
      |> validate_fk(get_field(changeset, :type))
    end
  end

  defp validate_fk(ids, type) do
    case length(ids) == count_by_ids(ids, type) do
      true -> []
      false -> [ingredients: "Invalid foreign keys"]
    end
  end

  defp validate_ingredients_id_uniqueness(changeset) do
    validate_change changeset, :ingredients, fn :ingredients, ingredients ->
      ingredients
      |> Enum.reduce_while({[], []}, &id_unique/2)
      |> elem(1)
    end
  end

  defp id_unique(changeset, {collected_ids, _msg}) do
    id = get_ingredient_id(changeset)
    case Enum.member?(collected_ids, id) do
      true -> {:halt, {false, [ingredients: "Ingredient id duplicated"]}}
      false -> {:cont, {collected_ids ++ [id], []}}
    end
  end

  defp get_ingredient_id(%{data: %INNMIngredient{}} = changeset) do
    get_field(changeset, :substance_id)
  end

  defp get_ingredient_id(%{data: % MedicationIngredient{}} = changeset) do
    get_field(changeset, :innm_id)
  end

  defp validate_ingedients_active_substance_uniqueness(changeset) do
    validate_change changeset, :ingredients, fn :ingredients, ingredients ->
      ingredients
      |> Enum.reduce_while({false, []}, &(active_substance_unique(get_field(&1, :is_active_substance), &2)))
      |> case do
           {false, _} -> [ingredients: "One and only one ingredient must be active"]
           {true, msg} -> msg
         end
    end
  end

  defp active_substance_unique(false, acc), do: {:cont, acc}
  defp active_substance_unique(true, {false, _msg}), do: {:cont, {true, []}}
  defp active_substance_unique(true, {true, _msg}), do:
    {:halt, {true, [ingredients: "One and only one ingredient must be active"]}}

  # counters

  defp count_by_ids(ids, @type_medication) do
    Medication
    |> where([m], m.id in ^ids)
    |> where([m], m.type == @type_innm)
    |> where([m], m.is_active)
    |> select(count("*"))
    |> PRMRepo.one()
  end

  defp count_by_ids(ids, @type_innm) do
    Substance
    |> where([s], s.id in ^ids)
    |> where([s], s.is_active)
    |> select(count("*"))
    |> PRMRepo.one()
  end
end
