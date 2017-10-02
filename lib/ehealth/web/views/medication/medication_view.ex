defmodule EHealth.Web.MedicationView do
  @moduledoc false
  use EHealth.Web, :view

  @medication_view_fields [
    :id,
    :name,
    :form,
    :type,
    :code_atc,
    :certificate,
    :certificate_expired_at,
    :container,
    :manufacturer,
    :package_qty,
    :package_min_qty,
    :is_active,
    :inserted_by,
    :updated_by,
  ]

  def render("index.json", %{medications: medications}) do
    render_many(medications, __MODULE__, "medication.json")
  end

  def render("drugs.json", %{drugs: drugs}) do
    render_many(drugs, __MODULE__, "drug.json", as: :drug)
  end

  def render("show.json", %{medication: medication}) do
    render_one(medication, __MODULE__, "medication.json")
  end

  def render("medication.json", %{medication: medication}) do
    medication
    |> Map.take(@medication_view_fields)
    |> Map.put(:ingredients, render_many(medication.ingredients, __MODULE__, "ingredient.json", as: :ingredient))
  end

  def render("ingredient.json", %{ingredient: ingredient}) do
    %{
      id: ingredient.medication_child_id,
      dosage: ingredient.dosage,
      is_primary: ingredient.is_primary,
    }
  end

  def render("drug.json", %{drug: drug}) do
    %{
      id: drug.innm_dosage_id,
      name: drug.innm_dosage_name,
      form: drug.innm_dosage_form,
      dosage: drug.innm_dosage_dosage,
      innm: %{
        id: drug.innm_id,
        name: drug.innm_name,
        name_original: drug.innm_name_original,
        sctid: drug.innm_sctid,
      },
      packages: Enum.map(drug.packages, fn {container, package_qty, package_min_qty} -> %{
        container_dosage: container,
        package_qty: package_qty,
        package_min_qty: package_min_qty,
      } end)
    }
  end
end
