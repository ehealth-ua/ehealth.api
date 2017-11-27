defmodule EHealth.Medications.Program.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "program_medication_search" do
    field :id, Ecto.UUID
    field :is_active, :boolean
    field :medical_program_id, Ecto.UUID
    field :medical_program_name, :string
    field :innm_dosage_id, Ecto.UUID
    field :innm_dosage_name, :string
    field :medication_id, Ecto.UUID
    field :medication_name, :string
  end
end
