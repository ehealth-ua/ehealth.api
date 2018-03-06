defmodule EHealth.Persons.Signed do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "person_signed" do
    field(:signed_content, :string)
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, ~w(signed_content)a)
    |> validate_required(~w(signed_content)a)
  end
end
