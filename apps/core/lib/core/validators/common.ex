defmodule Core.Validators.Common do
  @moduledoc false

  def validate_equal(value, value, _), do: :ok
  def validate_equal(_, _, error), do: error
end
