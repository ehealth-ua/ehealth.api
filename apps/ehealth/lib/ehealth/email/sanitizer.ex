defmodule EHealth.Email.Sanitizer do
  @moduledoc false

  def sanitize(value) when is_binary(value), do: String.downcase(value)
  def sanitize(value), do: value
end
