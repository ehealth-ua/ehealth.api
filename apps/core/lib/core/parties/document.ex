defmodule Core.Parties.Document do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset, warn: false

  @fields_optional ~w(issued_at issued_by)a
  @fields_required ~w(type number)a

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key false
  schema "documents" do
    field(:type, :string)
    field(:number, :string)
    field(:issued_at, :date)
    field(:issued_by, :string)
  end

  def changeset(%__MODULE__{} = doc, attrs) do
    doc
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end
