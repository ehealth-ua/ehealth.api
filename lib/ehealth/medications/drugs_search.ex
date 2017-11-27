defmodule EHealth.Medications.DrugsSearch do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_search" do
    field :innm_id, Ecto.UUID
    field :innm_name, :string
    field :innm_sctid, :string
    field :innm_dosage_id, Ecto.UUID
    field :innm_dosage_name, :string
    field :innm_dosage_form, :string
    field :medication_code_atc, :string
  end
end
