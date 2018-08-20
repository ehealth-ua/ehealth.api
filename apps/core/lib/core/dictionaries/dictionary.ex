defmodule Core.Dictionaries.Dictionary do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:name, :string, autogenerate: false}

  schema "dictionaries" do
    field(:labels, {:array, :string})
    field(:values, :map)
    field(:is_active, :boolean, default: false)
  end
end
