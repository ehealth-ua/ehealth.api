defmodule EHealth.Declarations.View do
  @moduledoc false

  def render_declarations(declarations) do
    Enum.map(declarations, &render_declaration(&1, :list))
  end

  def render_declaration(declaration), do: render_declaration(declaration, :one)

  def render_declaration(declaration, type) do
    declaration
    |> Map.take(fields(:declaration, type))
    |> Map.merge(%{
         "person" => Map.take(declaration["person"], fields(:person, type)),
         "division" => Map.take(declaration["division"], fields(:division, type)),
         "employee" => Map.take(declaration["employee"], fields(:employee, type)),
         "legal_entity" => Map.take(declaration["legal_entity"], fields(:legal_entity, type)),
       })
  end

  def fields(:employee, :one) do
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

  def fields(:employee, :list) do
    ~W(
      id
      position
      employee_type
    )
  end

  def fields(:person, :one) do
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

  def fields(:person, :list) do
    ~W(
      id
      first_name
      last_name
      second_name
    )
  end

  def fields(:division, :one) do
    ~W(
      id
      name
      legal_entity_id
      phones
      email
      addresses
      type
      mountain_group
    )
  end

  def fields(:division, :list) do
    ~W(
      id
      name
    )
  end

  def fields(:legal_entity, :one) do
    ~W(
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
      created_at
      modified_at
    )
  end

  def fields(:legal_entity, :list) do
    ~W(
      id
      name
      short_name
      edrpou
    )
  end

  def fields(:declaration, :one) do
    ~W(
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
    )
  end

  def fields(:declaration, :list) do
    ~W(
      id
      start_date
      end_date
      declaration_request_id
      inserted_at
      updated_at
    )
  end

end
