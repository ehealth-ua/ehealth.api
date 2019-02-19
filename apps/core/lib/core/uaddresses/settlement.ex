defmodule Core.Uaddresses.Settlement do
  @moduledoc false

  use Ecto.Schema

  alias Ecto.UUID

  embedded_schema do
    field(:type, :string)
    field(:name, :string)
    field(:mountain_group, :boolean)
    field(:koatuu, :string)
    field(:region_id, UUID)
    field(:district_id, UUID)
    field(:parent_settlement_id, UUID)

    timestamps()
  end
end
