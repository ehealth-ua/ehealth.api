defmodule EHealth.Web.DeclarationView do
  @moduledoc false

  use EHealth.Web, :view

  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.Parties.Party
  alias EHealth.Web.DivisionView
  alias EHealth.Web.LegalEntityView
  alias EHealth.Web.PersonView

  def render("index.json", %{declarations: declarations}) do
    render_many(declarations, __MODULE__, "declaration_list.json", as: :declaration)
  end

  def render("declaration_list.json", %{declaration: declaration}) do
    declaration
    |> Map.take(~w(
      id
      start_date
      end_date
      declaration_request_id
      inserted_at
      updated_at
      reason
      reason_description
      status
      declaration_number
    ))
    |> Map.merge(%{
      "person" => render_one(declaration["person"], __MODULE__, "person_short.json", as: :person),
      "division" => render_one(declaration["division"], __MODULE__, "division_short.json", as: :division),
      "employee" => render_one(declaration["employee"], __MODULE__, "employee_short.json", as: :employee),
      "legal_entity" =>
        render_one(declaration["legal_entity"], __MODULE__, "legal_entity_short.json", as: :legal_entity)
    })
  end

  def render("show.json", %{declaration: declaration}) do
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
      reason
      reason_description
      declaration_number
      content
    ))
    |> Map.merge(%{
      "person" => render_one(declaration["person"], __MODULE__, "person.json", as: :person),
      "division" => render_one(declaration["division"], __MODULE__, "division.json", as: :division),
      "employee" => render_one(declaration["employee"], __MODULE__, "employee.json", as: :employee),
      "legal_entity" => render_one(declaration["legal_entity"], __MODULE__, "legal_entity.json", as: :legal_entity)
    })
  end

  def render("cabinet_index.json", %{declarations: declarations, declaration_references: _, person: _} = view_data) do
    render_many(declarations, __MODULE__, "cabinet_declaration.json", view_data)
  end

  def render("cabinet_declaration.json", %{
        declaration: declaration,
        declaration_references: declaration_references,
        person: person
      }) do
    legal_entity = get_in(declaration_references, [:legal_entity, declaration["legal_entity_id"]])
    division = get_in(declaration_references, [:division, declaration["division_id"]])
    employee = get_in(declaration_references, [:employee, declaration["employee_id"]])

    declaration
    |> Map.take(~w(id start_date declaration_number status))
    |> Map.put("person", render(PersonView, "person_short.json", %{"person" => person}))
    |> Map.put("employee", Map.take(employee, ~w(id position)a))
    |> put_in(["employee", "party"], Map.take(employee.party, ~w(id first_name last_name second_name)a))
    |> Map.put("legal_entity", render(LegalEntityView, "legal_entity_short.json", %{legal_entity: legal_entity}))
    |> Map.put("division", render(DivisionView, "division_short.json", %{division: division}))
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
      gender
      first_name
      last_name
      second_name
      birth_date
      tax_id
      phones
      birth_date
      birth_country
      birth_settlement
      emergency_contact
      confidant_person
    )a)
  end

  def render("person_short.json", %{person: person}) do
    Map.take(person, ~w(
      id
      first_name
      last_name
      second_name
      birth_date
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
