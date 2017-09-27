defmodule EHealth.PRM.Medications.Medication.Search do
  @moduledoc false

  use Ecto.Schema

  alias EHealth.Ecto.StringLike

  @primary_key false
  schema "medication_search" do
    field :innm_dosage_id, Ecto.UUID
    field :innm_dosage_name, StringLike
    field :id, Ecto.UUID
    field :name, StringLike
    field :form, :string
    field :type, :string
    field :is_active, :boolean
  end
end
