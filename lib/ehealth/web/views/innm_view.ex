defmodule EHealth.Web.INNMView do
  @moduledoc false
  use EHealth.Web, :view

  def render("index.json", %{innms: innms}) do
    render_many(innms, __MODULE__, "innm.json")
  end

  def render("show.json", %{innm: innm}) do
    render_one(innm, __MODULE__, "innm.json")
  end

  def render("innm.json", %{innm: innm}) do
    %{
      id: innm.id,
      name: innm.name,
      type: innm.type,
      form: innm.form,
      is_active: innm.is_active,
      ingredients: render_many(innm.ingredients, __MODULE__, "ingredient.json", as: :ingredient),
      inserted_by: innm.inserted_by,
      inserted_at: innm.inserted_at,
      updated_at: innm.updated_at,
      updated_by: innm.updated_by,
    }
  end

  def render("ingredient.json", %{ingredient: ingredient}) do
    %{
      id: ingredient.substance_id,
      dosage: ingredient.dosage,
      is_active_substance: ingredient.is_active_substance,
    }
  end
end
