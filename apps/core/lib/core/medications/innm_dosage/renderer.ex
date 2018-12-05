defmodule Core.Medications.INNMDosage.Renderer do
  @moduledoc false

  def render("innm_dosage_short.json", innm_dosage, medication_qty) do
    dosage = innm_dosage.ingredients |> Enum.find(fn i -> i.is_primary end) |> Map.get(:dosage)

    %{
      medication_id: innm_dosage.id,
      medication_name: innm_dosage.name,
      dosage: dosage,
      form: innm_dosage.form,
      medication_qty: medication_qty
    }
  end
end
