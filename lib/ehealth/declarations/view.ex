defmodule EHealth.Declarations.View do
  @moduledoc false

  use EHealth.Web, :view

  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Employees.Employee
  alias EHealth.Parties.Party
  alias EHealth.Divisions.Division

  def render_declarations(declarations) do
    Enum.map(declarations, &render_declaration(&1, :list))
  end

  def render_declaration(declaration), do: render_declaration(declaration, :one)

  def render_declaration(declaration, :list) do
    legal_entity = render_one(declaration["legal_entity"], __MODULE__, "legal_entity_short.json", as: :legal_entity)
    employee = render_one(declaration["employee"], __MODULE__, "employee_short.json", as: :employee)
    division = render_one(declaration["division"], __MODULE__, "division_short.json", as: :division)
    person = render_one(declaration["person"], __MODULE__, "person_short.json", as: :person)

    declaration
    |> Map.take(~w(
      id
      start_date
      end_date
      declaration_request_id
      inserted_at
      updated_at
    ))
    |> Map.merge(%{
      "person" => person,
      "division" => division,
      "employee" => employee,
      "legal_entity" => legal_entity
    })
  end

  def render_declaration(declaration, :one) do
    declaration
    |> Map.take(~w(
      id
      start_date
      end_date
      signed_at
      status
      scope
      party
      declaration_request_id
      inserted_at
      updated_at
    ))
    |> Map.merge(%{
      "person" => render_one(declaration["person"], __MODULE__, "person.json", as: :person),
      "division" => render_one(declaration["division"], __MODULE__, "division.json", as: :division),
      "employee" => render_one(declaration["employee"], __MODULE__, "employee.json", as: :employee),
      "legal_entity" => render_one(declaration["legal_entity"], __MODULE__, "legal_entity.json", as: :legal_entity),
    })
  end

  def render("legal_entity.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    Map.take(legal_entity, ~w(
      id
      name
      short_name
      legal_form
      public_name
      edrpou
      status
      email
      phones
      addresses
      inserted_at
      updated_at
    )a)
  end

  def render("legal_entity_short.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    Map.take(legal_entity, ~w(
      id
      name
      short_name
      edrpou
    )a)
  end

  def render("legal_entity_employee.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    Map.take(legal_entity, ~w(
      type
      status
      short_name
      public_name
      owner_property_type
      name
      legal_form
      id
      edrpou
    )a)
  end

  def render("employee.json", %{employee: %Employee{} = employee}) do
    party = render_one(employee.party, __MODULE__, "party.json", as: :party)
    employee
    |> Map.take(~w(
      id
      position
      employee_type
      status
      start_date
      end_date
      division_id
      legal_entity_id
    )a)
    |> Map.put(:party, party)
    |> Map.put(:doctor, employee.additional_info)
  end

  def render("employee_short.json", %{employee: %Employee{} = employee}) do
    Map.take(employee, ~w(
      id
      position
      employee_type
    )a)
  end

  def render("person.json", %{person: person}) when is_map(person) do
    Map.take(person, ~w(
      id
      first_name
      last_name
      second_name
      birth_date
      tax_id
      phones
      birth_date
      birth_settlement
      emergency_contact
      confidant_person
    ))
  end

  def render("person_short.json", %{person: person}) do
    Map.take(person, ~w(
      id
      first_name
      last_name
      second_name
    ))
  end

  def render("division.json", %{division: %Division{} = division}) do
    Map.take(division, ~w(
      id
      name
      legal_entity_id
      phones
      email
      addresses
      type
      mountain_group
    )a)
  end

  def render("division_short.json", %{division: %Division{} = division}) do
    Map.take(division, ~w(
      id
      name
    )a)
  end

  def render("party.json", %{party: %Party{} = party}) do
    Map.take(party, ~w(
      tax_id
      second_name
      phones
      last_name
      id
      first_name
    )a)
  end
end
