defmodule EHealth.Utils.Phone do
  @moduledoc false

  def hide_number(<<code::bytes-size(6), _hidden::bytes-size(5), last_digits::bytes-size(2)>>) do
    code <> "*****" <> last_digits
  end
end
