defmodule EHealth.Declarations.View do
  @moduledoc false

  def render_declaration(declaration, person, legal_entity, division, employee) do
    declaration
    |> Map.take(fields(:one, :declaration))
    |> Map.put("person", Map.take(person, fields(:one, :division)))
    |> Map.put("division", Map.take(division, fields(:one, :division)))
    |> Map.put("employee", Map.take(employee, fields(:one, :employee)))
    |> Map.put("legal_entity", Map.take(legal_entity, fields(:one, :legal_entity)))
  end

  def fields(:one, :employee) do
    ~W(
      id
      position
      employee_type
      status
      start_date
      end_date
      party
      division_id
      legal_entity
      doctor
    )
  end

  def fields(:one, :person) do
    ~W(
      id
      first_name
      last_name
      second_name
      birth_date
      tax_id
      phones
      birth_country
      birth_settlement
    )
  end

  def fields(:one, :division) do
    ~W(
      id
      name
      legal_entity_id
      type
      mountain_group
    )
  end

  def fields(:one, :legal_entity) do
    ~W(
      id
      name
      short_Name
      legal_form
      public_name
      edrpou
      status
      email
      phones
      addresses
      created_at
      modified_at
    )
  end

  def fields(:one, :declaration) do
    ~W(
      id
      start_date
      end_date
      inserted_at
      updated_at
    )
  end

end
