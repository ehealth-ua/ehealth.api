defmodule EHealth.Validators.TaxID do
  @moduledoc """
  Tax ID validator
  """

  @ratios [-1, 5, 7, 9, 4, 6, 10, 5, 7]

  def validate(tax_id, true), do: Regex.match?(~r/^([0-9]{9}|[А-ЯЁЇIЄҐ]{4}\d{6})$/, tax_id)
  def validate(tax_id, _), do: validate(tax_id)
  def validate(tax_id) when byte_size(tax_id) != 10, do: false
  def validate("0000000000"), do: false

  def validate(tax_id) do
    if Regex.match?(~r/^[0-9]{10}$/, tax_id) do
      {check_sum, i} =
        Enum.reduce(@ratios, {0, 0}, fn x, {acc, i} -> {acc + x * String.to_integer(String.at(tax_id, i)), i + 1} end)

      check_number =
        check_sum
        |> rem(11)
        |> rem(10)

      last_number =
        tax_id
        |> String.at(i)
        |> String.to_integer()

      last_number == check_number
    else
      false
    end
  end
end
