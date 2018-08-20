defmodule Core.Ecto.StringLike do
  @moduledoc false

  @behaviour Ecto.Type

  def type, do: :string

  def cast(string) when is_binary(string) do
    {:ok, {string, :like}}
  end

  def cast(_), do: :error

  def load(string) when is_binary(string), do: {:ok, {string, :like}}

  def dump(string) when is_binary(string), do: {:ok, {string, :like}}
  def dump(_), do: :error
end
