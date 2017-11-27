defmodule EHealth.Medications.Validator do
  @moduledoc """
  Medications validator.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias EHealth.PRMRepo
  alias EHealth.Medications.INNM
  alias EHealth.MedicalPrograms.MedicalProgram
  alias EHealth.Medications.Medication
  alias EHealth.Medications.INNMDosage
  alias EHealth.Medications.INNMDosage.Ingredient, as: INNMIngredient
  alias EHealth.Medications.Medication.Ingredient, as: MedicationIngredient

  @type_innm_dosage INNMDosage.type()
  @type_medication Medication.type()

  def validate_ingredients(changeset) do
    changeset
    |> validate_ingredients_fk()
    |> validate_ingredients_id_uniqueness()
    |> validate_ingedients_active_innm_uniqueness()
    |> validate_ingredients_dosage()
  end

  def validate_package_quantity(changeset) do
    qty = get_field(changeset, :package_qty)
    min_qty = get_field(changeset, :package_min_qty)
    case rem(qty, min_qty) do
      0 -> changeset
      _ -> add_error(changeset, :package_qty, "Invalid package quantity")
    end
  end

  def validate_medication_is_active(changeset) do
    validate_change changeset, :medication_id, fn :medication_id, medication_id ->
      case PRMRepo.get_by(Medication, [id: medication_id, type: Medication.type(), is_active: true]) do
        nil -> [medication_id: "Medication is not active"]
        _ -> []
      end
    end
  end

  def validate_medical_program_is_active(changeset) do
    validate_change changeset, :medical_program_id, fn :medical_program_id, medical_program_id ->
      case PRMRepo.get_by(MedicalProgram, [id: medical_program_id, is_active: true]) do
        nil -> [medical_program_id: "Medical program is not active"]
        _ -> []
      end
    end
  end

  def validate_program_medication_is_active(%{changes: %{is_active: false}} = changeset) do
    err_msg = "To deactivate medication brand within the program firstly disable medical_request_allowed"
    case get_field(changeset, :medication_request_allowed) do
      true -> add_error(changeset, :is_active, err_msg)
      _ -> changeset
    end
  end
  def validate_program_medication_is_active(changeset) do
    changeset
  end

  def validate_program_medication_requests_allowed(%{changes: %{medication_request_allowed: true}} = changeset) do
    err_msg = "To allow medication request firstly enable program medication"
    case get_field(changeset, :is_active) do
      false -> add_error(changeset, :medication_request_allowed, err_msg)
      _ -> changeset
    end
  end
  def validate_program_medication_requests_allowed(changeset) do
    changeset
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
    get_field(changeset, :innm_child_id)
  end

  defp get_ingredient_id(%{data: % MedicationIngredient{}} = changeset) do
    get_field(changeset, :medication_child_id)
  end

  defp validate_ingedients_active_innm_uniqueness(changeset) do
    validate_change changeset, :ingredients, fn :ingredients, ingredients ->
      ingredients
      |> Enum.reduce_while({false, []}, &(active_innm_unique(get_field(&1, :is_primary), &2)))
      |> case do
           {false, _} -> [ingredients: "One and only one ingredient must be active"]
           {true, msg} -> msg
         end
    end
  end

  defp active_innm_unique(false, acc), do: {:cont, acc}
  defp active_innm_unique(true, {false, _msg}), do: {:cont, {true, []}}
  defp active_innm_unique(true, {true, _msg}), do:
    {:halt, {true, [ingredients: "One and only one ingredient must be active"]}}

  defp validate_ingredients_dosage(%{data: %Medication{}} = changeset) do
    numerator = get_field(changeset, :container)["numerator_unit"]

    validate_change changeset, :ingredients, fn :ingredients, ingredients ->
      Enum.reduce_while(ingredients, false, &(validate_ingredients_numerator(&1, numerator, &2)))
    end
  end
  defp validate_ingredients_dosage(changeset) do
    changeset
  end

  defp validate_ingredients_numerator(ingredient, numerator, _) do
    err_msg = "Denumerator unit from Dosage ingredients must be equal Numerator unit from Container medication"

    case get_field(ingredient, :dosage)["denumerator_unit"] == numerator do
      false -> {:halt, [ingredients: err_msg]}
      true -> {:cont, []}
    end
  end

  # counters

  defp count_by_ids(ids, @type_medication) do
    Medication
    |> where([m], m.id in ^ids)
    |> where([m], m.type == @type_innm_dosage)
    |> where([m], m.is_active)
    |> select(count("*"))
    |> PRMRepo.one()
  end

  defp count_by_ids(ids, @type_innm_dosage) do
    INNM
    |> where([s], s.id in ^ids)
    |> where([s], s.is_active)
    |> select(count("*"))
    |> PRMRepo.one()
  end
end
