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
    medication
  end
end
