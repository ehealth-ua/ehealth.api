defmodule EHealth.Web.Cabinet.DeclarationView do
  @moduledoc false

  use EHealth.Web, :view

  alias EHealth.Web.PersonView
  alias EHealth.Web.LegalEntityView
  alias EHealth.Web.DivisionView

  def render("list_declarations.json", %{declarations: declarations, employees: _, person: _} = view_data) do
    render_many(declarations, __MODULE__, "declaration.json", view_data)
  end

  def render("declaration.json", %{declaration: declaration, employees: employees, person: person}) do
    %{legal_entity: legal_entity, division: division, party: party} = employee = employees[declaration["employee_id"]]

    declaration
    |> Map.take(~w(id start_date declaration_number status))
    |> Map.put("person", render(PersonView, "person_short.json", %{"person" => person}))
    |> Map.put("employee", Map.take(employee, ~w(id position)a))
    |> put_in(["employee", "party"], Map.take(party, ~w(id first_name last_name second_name)a))
    |> Map.put("legal_entity", render(LegalEntityView, "legal_entity_short.json", %{legal_entity: legal_entity}))
    |> Map.put("division", render(DivisionView, "division_short.json", %{division: division}))
  end
end
