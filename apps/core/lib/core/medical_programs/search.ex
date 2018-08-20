defmodule Core.MedicalPrograms.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medical_programs_search" do
    field(:id, Ecto.UUID)
    field(:name, Core.Ecto.StringLike)
    field(:is_active, :boolean)
  end
end
