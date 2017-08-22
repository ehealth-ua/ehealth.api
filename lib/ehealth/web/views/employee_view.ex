defmodule EHealth.Web.EmployeeView do
  @moduledoc false

  use EHealth.Web, :view

  alias EHealth.Web.PartyView
  alias EHealth.PRM.Parties.Schema, as: Party
  alias EHealth.PRM.Divisions.Schema, as: Division
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.Employees.Schema, as: Employee

  @doctor Employee.type(:doctor)

  def render("index.json", %{employees: employees}) do
    render_many(employees, __MODULE__, "employee.json")
  end

  def render("employee_short.json", %{"employee" => employee}) do
    %{
      "id" => Map.get(employee, "id"),
      "position" => Map.get(employee, "position"),
      "party" => render(PartyView, "party_short.json", Map.take(employee, ["party"])),
    }
  end
  def render("employee_short.json", _), do: %{}

  def render("employee.json", %{employee: %{employee_type: @doctor, additional_info: info} = employee}) do
    employee
    |> render_employee()
    |> render_doctor(info)
  end
  def render("employee.json", %{employee: employee}) do
    render_employee(employee)
  end

  def render_employee(employee) do
    %{
      id: employee.id,
      position: employee.position,
      status: employee.status,
      employee_type: employee.employee_type,
      start_date: employee.start_date,
      end_date: employee.end_date,
    }
    |> render_association(employee.party, :party, employee.party_id)
    |> render_association(employee.division, :division, employee.division_id)
    |> render_association(employee.legal_entity, :legal_entity, employee.legal_entity_id)
  end

  def render_association(map, %Ecto.Association.NotLoaded{}, key, default) do
    key =
      key
      |> Atom.to_string()
      |> Kernel.<>("_id")
      |> String.to_atom()

    Map.put(map, key, default)
  end
  def render_association(map, %Party{} = party, key, _default) do
    data = %{
      id: party.id,
      first_name: party.first_name,
      last_name: party.last_name,
      second_name: party.second_name,
      birth_date: party.birth_date,
      gender: party.gender,
      tax_id: party.tax_id,
      documents: party.documents,
      phones: party.phones
    }
    Map.put(map, key, data)
  end
  def render_association(map, %Division{} = division, key, _default) do
    data = %{
      id: division.id,
      type: division.type,
      legal_entity_id: division.legal_entity_id,
      mountain_group: division.mountain_group,
    }
    Map.put(map, key, data)
  end
  def render_association(map, %LegalEntity{} = legal_entity, key, _default) do
    data = %{
      id: legal_entity.id,
      name: legal_entity.name,
      short_name: legal_entity.short_name,
      public_name: legal_entity.public_name,
      type: legal_entity.type,
      edrpou: legal_entity.edrpou,
      status: legal_entity.status,
      owner_property_type: legal_entity.owner_property_type,
      legal_form: legal_entity.legal_form,
    }
    Map.put(map, key, data)
  end
  def render_association(map, _assoc, key, default), do: Map.put(map, key, default)

  defp render_doctor(map, info) do
    Map.put(map, :doctor, info)
  end
end
