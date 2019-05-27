defmodule Core.MedicalPrograms.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:id, Ecto.UUID)
    field(:name, Core.Ecto.StringLike)
    field(:type, :string)
    field(:is_active, :boolean)
  end
end
