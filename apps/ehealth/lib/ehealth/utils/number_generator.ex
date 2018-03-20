defmodule EHealth.Utils.NumberGenerator do
  @moduledoc """
    Module that generates human readable number with pattern
    XXXX-12E4-52A8-7TAA randomly generated numbers and letters A, E, H, K, M, P, T, X.
  """
  use Confex, otp_app: :ehealth

  @human_readble_symbols ~w(0 1 2 3 4 5 6 7 8 9 A E H K M P T X)
  @ver_1 "0000-"

  def generate(version, blocks \\ 3) do
    do_generate(version, blocks)
  end

  defp do_generate(1, blocks) do
    sequence =
      1..blocks
      |> Enum.map(fn _ -> get_combination_of(4) end)
      |> Enum.join("-")

    @ver_1 <> sequence
  end

  defp get_combination_of(number_length) do
    1..number_length
    |> Enum.map(fn _ -> Enum.random(@human_readble_symbols) end)
    |> Enum.join()
  end

  def generate_otp_verification_code do
    1..Confex.fetch_env!(:ehealth, :medication_request_request)[:otp_code_length]
    |> Enum.map(fn _ -> :rand.uniform(9) end)
    |> Enum.join()
  end
end
