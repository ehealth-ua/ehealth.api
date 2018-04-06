defmodule EHealth.Cabinet.Requests.DeclarationsSearch do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:status, :string)
    field(:start_year, :string)
  end

  @year_regexp ~r/2\d{3}$/

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, __MODULE__.__schema__(:fields))
    |> validate_format(:start_year, @year_regexp)
  end
end
