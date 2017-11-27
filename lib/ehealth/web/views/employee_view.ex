defmodule EHealth.Web.EmployeeView do
  @moduledoc false

  use EHealth.Web, :view

  alias EHealth.Web.PartyView
  alias EHealth.Parties.Party
  alias EHealth.Divisions.Division
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Employees.Employee

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  def render("index.json", %{employees: employees}) do
    render_many(employees, __MODULE__, "employee_list.json")
  end

  def render("employee_list.json", %{employee: employee}) do
    employee
    |> Map.take(~w(
      id
      position
      employee_type
      status
      start_date
      end_date
    )a)
    |> Map.put(:party, Map.take(employee.party, ~w(id first_name second_name last_name)a))
    |> render_association(employee.division, :division)
    |> render_association(employee.legal_entity, :legal_entity)
    |> put_list_info(employee)
  end

  def render("employee_short.json", %{"employee" => employee}) do
    %{
      "id" => Map.get(employee, "id"),
      "position" => Map.get(employee, "position"),
      "party" => render(PartyView, "party_short.json", Map.take(employee, ["party"])),
    }
  end
  def render("employee_short.json", %{employee: employee}) do
    %{
      "id" => employee.id,
      "position" => employee.position,
      "party" => render(PartyView, "party_short.json", %{party: employee.party}),
    }
  end
  def render("employee_short.json", _), do: %{}

  def render("employee_private.json", %{employee: employee}) do
    %{
      "id" => employee.id,
      "position" => employee.position,
      "party" => render(PartyView, "party_private.json", %{party: employee.party}),
    }
  end
  def render("employee_private.json", _), do: %{}

  def render("employee.json", %{employee: %{employee_type: @doctor, additional_info: info} = employee}) do
    employee
    |> render_employee()
    |> render_doctor(info)
  end
  def render("employee.json", %{employee: %{employee_type: @pharmacist, additional_info: info} = employee}) do
    employee
    |> render_employee()
    |> render_pharmacist(info)
  end
  def render("employee.json", %{employee: employee}) do
    render_employee(employee)
  end

  def render_employee(employee) do
    employee
    |> Map.take(~w(
      id
      position
      status
      employee_type
      start_date
      end_date
    )a)
    |> render_association(employee.party, :party)
    |> render_association(employee.division, :division)
    |> render_association(employee.legal_entity, :legal_entity)
  end

  defp render_association(map, %Party{} = party, key) do
    data = Map.take(party, ~w(
      id
      first_name
      last_name
      second_name
      birth_date
      gender
      tax_id
      documents
      phones
    )a)
    Map.put(map, key, data)
  end
  defp render_association(map, %Division{} = division, key) do
    data = Map.take(division, ~w(
      id
      name
      status
      type
      legal_entity_id
      mountain_group
    )a)
    Map.put(map, key, data)
  end
  defp render_association(map, %LegalEntity{} = legal_entity, key) do
    data = Map.take(legal_entity, ~w(
      id
      name
      short_name
      public_name
      type
      edrpou
      status
      owner_property_type
      legal_form
      mis_verified
    )a)
    Map.put(map, key, data)
  end
  defp render_association(map, _, _), do: map

  defp render_doctor(map, info) do
    Map.put(map, :doctor, info)
  end

  defp render_pharmacist(map, info) do
    Map.put(map, :pharmacist, info)
  end

  defp put_list_info(map, %Employee{employee_type: @doctor} = employee) do
    Map.put(map, :doctor, %{"specialities" => Map.get(employee.additional_info, "specialities")})
  end
  defp put_list_info(map, %Employee{employee_type: @pharmacist} = employee) do
    Map.put(map, :pharmacist, %{"specialities" => Map.get(employee.additional_info, "specialities")})
  end
  defp put_list_info(map, _), do: map
end
