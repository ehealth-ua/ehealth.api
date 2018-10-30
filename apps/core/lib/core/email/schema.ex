defmodule Core.Email.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "email" do
    field(:data, :map)
    field(:from, :string)
    field(:subject, :string)

    embeds_many :to, Receiver do
      field(:receiver, :string)
    end
  end
end
