defmodule Core.Dictionaries.DictionarySearch do
  @moduledoc false

  use Ecto.Schema

  schema "dictionary_search" do
    field(:name, :string)
    field(:is_active, :boolean)
  end
end
