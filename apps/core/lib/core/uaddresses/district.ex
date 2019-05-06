defmodule Core.Uaddresses.District do
  @moduledoc false

  use Ecto.Schema

  alias Ecto.UUID

  embedded_schema do
    field(:name, :string)
    field(:koatuu, :string)
    field(:region_id, UUID)

    timestamps(type: :utc_datetime_usec)
  end
end
