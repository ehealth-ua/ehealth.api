defmodule EHealth.Parties.Phone do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    type
    number
  )a

  @derive {Poison.Encoder, except: [:__meta__]}

  @primary_key false
  schema "phones" do
    field :type, :string
    field :number, :string
  end

  def changeset(%__MODULE__{} = phone, attrs) do
    phone
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
