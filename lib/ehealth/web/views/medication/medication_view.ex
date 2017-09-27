defmodule EHealth.Web.MedicationView do
  @moduledoc false
  use EHealth.Web, :view

  def render("index.json", %{medications: medications}) do
    render_many(medications, __MODULE__, "medication.json")
  end

  def render("show.json", %{medication: medication}) do
    render_one(medication, __MODULE__, "medication.json")
  end

  def render("medication.json", %{medication: medication}) do
    %{
      id: medication.id,
      name: medication.name,
      form: medication.form,
      type: medication.type,
      code_atc: medication.code_atc,
      certificate: medication.certificate,
      certificate_expired_at: medication.certificate_expired_at,
      container: medication.container,
      manufacturer: medication.manufacturer,
      package_qty: medication.package_qty,
      package_min_qty: medication.package_min_qty,
      is_active: medication.is_active,
      inserted_by: medication.inserted_by,
      updated_by: medication.updated_by,
      ingredients: render_many(medication.ingredients, __MODULE__, "ingredient.json", as: :ingredient),
    }
  end

  def render("ingredient.json", %{ingredient: ingredient}) do
    %{
      id: ingredient.medication_child_id,
      dosage: ingredient.dosage,
      is_primary: ingredient.is_primary,
    }
  end
end
