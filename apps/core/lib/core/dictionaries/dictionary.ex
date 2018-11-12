defmodule Core.Dictionaries.Dictionary do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "dictionaries" do
    field(:name, :string)
    field(:labels, {:array, :string})
    field(:values, :map)
    field(:is_active, :boolean, default: false)
  end
end
