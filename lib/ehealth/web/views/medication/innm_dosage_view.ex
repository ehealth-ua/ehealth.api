defmodule EHealth.Web.INNMDosageView do
  @moduledoc false
  use EHealth.Web, :view

  @view_fields [:id, :name, :type, :form, :is_active, :inserted_by, :updated_by, :inserted_at, :updated_at]

  def render("index.json", %{innm_dosages: innm_dosages}) do
    render_many(innm_dosages, __MODULE__, "innm_dosage.json")
  end

  def render("show.json", %{innm_dosage: innm_dosage}) do
    render_one(innm_dosage, __MODULE__, "innm_dosage.json")
  end

  def render("innm_dosage.json", %{innm_dosage: innm_dosage}) do
    innm_dosage
    |> Map.take(@view_fields)
    |> Map.put(
      :ingredients,
      render_many(innm_dosage.ingredients, __MODULE__, "ingredient.json", as: :ingredient)
    )
  end

  def render("innm_dosage_short.json", %{innm_dosage: innm_dosage, medication_qty: medication_qty}) do
    dosage = innm_dosage.ingredients |> Enum.filter(fn i -> i.is_primary end) |> Enum.at(0) |> Map.get(:dosage)

    %{
      medication_id: innm_dosage.id,
      medication_name: innm_dosage.name,
      dosage: dosage,
      form: innm_dosage.form,
      medication_qty: medication_qty
    }
  end

  def render("ingredient.json", %{ingredient: ingredient}) do
    %{
      id: ingredient.innm_child_id,
      name: ingredient.innm.name,
      dosage: ingredient.dosage,
      is_primary: ingredient.is_primary
    }
  end
end
