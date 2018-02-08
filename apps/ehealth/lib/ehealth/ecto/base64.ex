defmodule EHealth.Ecto.Base64 do
  @moduledoc false

  @behaviour Ecto.Type

  def type, do: :string

  def cast(string) when is_binary(string), do: Base.decode64(string)
  def cast(_), do: :error

  def load(string) when is_binary(string), do: {:ok, string}

  def dump(string) when is_binary(string), do: {:ok, string}
  def dump(_), do: :error
end
