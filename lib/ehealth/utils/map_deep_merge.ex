defmodule EHealth.Utils.MapDeepMerge do
  @moduledoc """
  Helper functions for deep map merge
  """

  def merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, %{} = left, %{} = right), do: merge(left, right)
  defp deep_resolve(_key, _left, right), do: right
end
