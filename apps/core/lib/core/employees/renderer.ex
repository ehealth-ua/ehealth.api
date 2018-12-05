defmodule Core.Employees.Renderer do
  @moduledoc false

  alias Core.Parties.Renderer, as: PartiesRenderer

  def render("employee_private.json", nil), do: %{}

  def render("employee_private.json", employee) do
    %{
      "id" => employee.id,
      "position" => employee.position,
      "party" => PartiesRenderer.render("party_private.json", employee.party)
    }
  end
end
