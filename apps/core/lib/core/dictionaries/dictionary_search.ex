defmodule Core.Dictionaries.DictionarySearch do
  @moduledoc false

  use Ecto.Schema

  embedded_schema do
    field(:name, :string)
    field(:is_active, :boolean)
  end
end
