defmodule EHealth.Parties.Document do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    type
    number
  )a

  @derive {Poison.Encoder, except: [:__meta__]}

  @primary_key false
  schema "documents" do
    field :type, :string
    field :number, :string
  end

  def changeset(%__MODULE__{} = doc, attrs) do
    doc
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
