defmodule Core.Divisions.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:ids, Core.Ecto.CommaParamsUUID)
    field(:name, :string)
    field(:type, :string)
    field(:legal_entity_id, Ecto.UUID)
    field(:status, :string)
  end
end
