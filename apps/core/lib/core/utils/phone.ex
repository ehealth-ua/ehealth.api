defmodule Core.Utils.Phone do
  @moduledoc false

  def hide_number(number) when is_binary(number), do: do_hide_number(number)
  def hide_number(number), do: number

  def do_hide_number(<<code::bytes-size(6), _hidden::bytes-size(5), last_digits::bytes-size(2)>>) do
    "#{code}*****#{last_digits}"
  end
end
