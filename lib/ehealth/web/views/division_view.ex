defmodule EHealth.Web.DivisionView do
  @moduledoc false

  def render("division_short.json", %{"division" => division}) do
    %{
      "id" => Map.get(division, "id"),
      "name" => Map.get(division, "name"),
      "type": Map.get(division, "type"),
    }
  end
  def render("division_short.json", _), do: %{}
end
