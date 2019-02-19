defmodule Core.Uaddresses.Region do
  @moduledoc false

  use Ecto.Schema

  embedded_schema do
    field(:name, :string)
    field(:koatuu, :string)

    timestamps()
  end
end
