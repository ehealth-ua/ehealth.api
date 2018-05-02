defmodule EHealth.Utils.NumberGenerator do
  @moduledoc """
    Module that generates human readable number with pattern
    XXXX-12E4-52A8-7TAA randomly generated numbers and letters A, E, H, K, M, P, T, X.
  """
  use Confex, otp_app: :ehealth

  @human_readble_symbols ~w(0 A 1 E 2 H 3 K 4 M 5 P 6 T 7 X 8 9)
  # Number of symbols available, set as module attribute for better performance
  @options_count 18
  @ver_1 "0000-"

  def generate_from_sequence(1, sequence, blocks \\ 3) do
    number =
      ""
      |> do_generate_from_sequence(sequence)
      |> String.pad_trailing(blocks * 4, "0")

    number =
      0..(blocks - 2)
      |> Enum.reduce([], fn i, acc -> acc ++ [String.slice(number, i * 4, 4)] end)
      |> Enum.join("-")

    "#{@ver_1}#{number}"
  end

  defp do_generate_from_sequence(number, reminder) do
    new_number = number <> to_string(Enum.at(@human_readble_symbols, rem(reminder, @options_count)))
    div_number = div(reminder, @options_count)

    case div_number do
      0 -> new_number
      _ -> do_generate_from_sequence(new_number, div_number)
    end
  end

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
