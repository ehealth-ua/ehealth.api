defmodule Core.Uaddresses.Region do
  @moduledoc false

  use Ecto.Schema

  embedded_schema do
    field(:name, :string)
    field(:koatuu, :string)

    timestamps(type: :utc_datetime_usec)
  end
end
