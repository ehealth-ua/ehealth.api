defmodule EHealth.Web.EmployeeView do
  @moduledoc false

  use EHealth.Web, :view

  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.Employees.Renderer, as: EmployeesRenderer
  alias Core.LegalEntities.LegalEntity
  alias Core.Parties.Party
  alias EHealth.Web.PartyView

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  def render("index.json", %{employees: employees}) do
    Enum.map(employees, fn employee ->
      render_one(employee, __MODULE__, "employee_list.json", %{employee: employee})
    end)
  end

  def render("employee_list.json", %{employee: employee}) do
    party =
      employee.party
      |> Map.take(~w(id first_name second_name last_name no_tax_id)a)
      |> Map.merge(%{declaration_count: 0, declaration_limit: 0})

    employee
    |> Map.take(~w(
      id
      position
      employee_type
      status
      start_date
      end_date
    )a)
    |> Map.put(:party, party)
    |> render_association(employee.division)
    |> render_association(employee.legal_entity)
    |> put_list_info(employee)
  end

  def render("employee_short.json", %{"employee" => employee}) do
    %{
      "id" => Map.get(employee, "id"),
      "position" => Map.get(employee, "position"),
      "party" => render(PartyView, "party_short.json", Map.take(employee, ["party"]))
    }
  end

  def render("employee_short.json", %{employee: employee}) do
    %{
      "id" => employee.id,
      "position" => employee.position,
      "party" => render(PartyView, "party_short.json", %{party: employee.party})
    }
  end

  def render("employee_short.json", _), do: %{}

  def render("employee_private.json", employee_data) do
    EmployeesRenderer.render("employee_private.json", employee_data)
  end

  def render("employee.json", %{employee: %{employee_type: @doctor, additional_info: info} = employee}) do
    employee
    |> render_employee()
    |> render_doctor(Map.put(info, "specialities", get_employee_specialities(employee)))
  end

  def render("employee.json", %{employee: %{employee_type: @pharmacist, additional_info: info} = employee}) do
    employee
    |> render_employee()
    |> render_pharmacist(Map.put(info, "specialities", get_employee_specialities(employee)))
  end

  def render("employee.json", %{employee: employee}) do
    render_employee(employee)
  end

  def render("employee_users_short.json", %{employee: employee}) do
    employee
    |> Map.take(~w(id legal_entity_id)a)
    |> Map.put(:party, render(PartyView, "party_users.json", %{party: employee.party}))
  end

  def render("document.json", %{document: document}) do
    Map.take(document, ~w(type number issued_at issued_by)a)
  end

  def render("phone.json", %{phone: phone}) do
    Map.take(phone, ~w(type number)a)
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
    |> render_association(employee.party)
    |> render_association(employee.division)
    |> render_association(employee.legal_entity)
  end

  defp render_association(map, %Party{} = party) do
    data =
      party
      |> Map.take(~w(
        id
        first_name
        last_name
        second_name
        birth_date
        gender
        tax_id
        no_tax_id
        about_myself
        working_experience
      )a)
      |> Map.merge(%{declaration_limit: 0, declaration_count: 0})
      |> Map.put(:documents, render_many(party.documents, __MODULE__, "document.json", as: :document))
      |> Map.put(:phones, render_many(party.phones, __MODULE__, "phone.json", as: :phone))

    Map.put(map, :party, data)
  end

  defp render_association(map, %Division{} = division) do
    data = Map.take(division, ~w(
      id
      name
      status
      type
      legal_entity_id
      mountain_group
    )a)
    Map.put(map, :division, data)
  end

  defp render_association(map, %LegalEntity{} = legal_entity) do
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
    Map.put(map, :legal_entity, data)
  end

  defp render_association(map, _), do: map

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

  defp get_employee_specialities(employee) do
    speciality = employee.speciality
    party_specialities = employee.party.specialities || []

    party_specialities =
      party_specialities
      |> Enum.filter(&(Map.get(&1, "speciality") != speciality["speciality"]))
      |> Enum.map(&Map.put(&1, "speciality_officio", false))

    case speciality do
      nil -> party_specialities
      speciality -> [speciality | party_specialities]
    end
  end
end
