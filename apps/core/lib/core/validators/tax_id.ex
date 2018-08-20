defmodule Core.Validators.TaxID do
  @moduledoc """
  Tax ID validator
  """

  alias Core.Validators.Error

  @ratios [-1, 5, 7, 9, 4, 6, 10, 5, 7]

  def validate(tax_id, true, error) do
    if Regex.match?(~r/^([0-9]{9}|[А-ЯЁЇIЄҐ]{2}\d{6})$/ui, tax_id) do
      :ok
    else
      Error.dump(error)
    end
  end

  def validate(tax_id, _, error), do: validate(tax_id, error)
  def validate(tax_id, error) when byte_size(tax_id) != 10, do: Error.dump(error)
  def validate("0000000000", error), do: Error.dump(error)

  def validate(tax_id, error) do
    with true <- Regex.match?(~r/^[0-9]{10}$/, tax_id) do
      {check_sum, i} =
        Enum.reduce(@ratios, {0, 0}, fn x, {acc, i} ->
          {acc + x * String.to_integer(String.at(tax_id, i)), i + 1}
        end)

      check_number =
        check_sum
        |> rem(11)
        |> rem(10)

      last_number =
        tax_id
        |> String.at(i)
        |> String.to_integer()

      if last_number == check_number, do: :ok, else: Error.dump(error)
    else
      _ -> Error.dump(error)
    end
  end
end
