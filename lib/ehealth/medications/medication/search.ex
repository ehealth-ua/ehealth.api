defmodule EHealth.Medications.Medication.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_search" do
    field :innm_dosage_id, Ecto.UUID
    field :innm_dosage_name, :string
    field :id, Ecto.UUID
    field :name, :string
    field :form, :string
    field :type, :string
    field :is_active, :boolean
  end
end
