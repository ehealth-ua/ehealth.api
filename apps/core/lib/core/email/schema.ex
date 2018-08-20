defmodule Core.Email.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "email" do
    field(:data, :map)
    field(:from, :string)
    field(:to, :string)
    field(:subject, :string)
  end
end
