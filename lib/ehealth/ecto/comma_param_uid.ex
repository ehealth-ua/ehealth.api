defmodule EHealth.Ecto.CommaParamsUUID do
  @moduledoc false

  @behaviour Ecto.Type

  alias Ecto.UUID

  def type, do: :string

  def cast(string) when is_binary(string) do
    string
    |> String.split(",")
    |> valid_uuid_params?()
    |> case do
         true  -> {:ok, string}
         false -> :error
       end
  end

  def cast(_), do: :error

  def load(string) when is_binary(string), do: {:ok, string}

  def dump(string) when is_binary(string), do: {:ok, string}
  def dump(_), do: :error

  def valid_uuid_params?(comma_params) do
    Enum.reduce_while(comma_params, true, fn (i, acc) ->
      case UUID.cast(i) do
        {:ok, _} -> {:cont, acc}
        _        -> {:halt, false}
      end
    end)
  end
end
