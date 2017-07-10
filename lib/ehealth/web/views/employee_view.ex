defmodule EHealth.Web.EmployeeView do
  @moduledoc false

  use EHealth.Web, :view

  alias EHealth.Web.PartyView

  def render("employee_short.json", %{"employee" => employee}) do
    %{
      "id" => Map.get(employee, "id"),
      "position" => Map.get(employee, "position"),
      "party" => render(PartyView, "party_short.json", Map.take(employee, ["party"])),
    }
  end
  def render("employee_short.json", _), do: %{}
end
