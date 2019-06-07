defmodule Core.DeclarationRequests.Urgent do
  @moduledoc false

  alias Core.Utils.Phone

  def filter_authentication_method(%{"number" => number} = method) do
    Map.put(method, "number", Phone.hide_number(number))
  end

  def filter_authentication_method(method), do: method
end
