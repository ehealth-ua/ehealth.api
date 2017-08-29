defmodule EHealth.Web.GlobalParameterView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{global_parameters: global_parameters}) do
    Enum.reduce(global_parameters, %{}, fn(x, acc) ->
      Map.put(acc, x.parameter, x.value)
    end)
  end
end
