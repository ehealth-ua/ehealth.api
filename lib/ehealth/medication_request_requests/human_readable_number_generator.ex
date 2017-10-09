defmodule EHealth.MedicationRequestRequest.HumanReadableNumberGenerator do
  @moduledoc """
    Module that generates human readable number with pattern
    XXXX-12E4-52A8-P01 randomly generated numbers and letters A, E, H, K, M, P, T, X.
  """

  @human_readble_symbols ~w(0 1 2 3 4 5 6 7 8 9 A E H K M P T X)
  @ver_1 "0000-"

  def generate(version) do
    do_generate(version)
  end

  defp do_generate(1) do
    sequence =
      1..3
      |> Enum.map(fn _ -> get_combination_of(4) end)
      |> Enum.join("-")
    @ver_1 <> sequence
  end

  defp get_combination_of(number_length) do
    1..number_length
    |> Enum.map(fn _ -> Enum.random(@human_readble_symbols) end)
    |> Enum.join
  end
end
