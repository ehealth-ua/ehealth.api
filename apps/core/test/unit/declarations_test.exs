defmodule Core.Unit.DeclarationsTest do
  @moduledoc false

  use ExUnit.Case
  alias Core.Declarations.API
  alias Ecto.UUID

  test "fetch_related_ids" do
    p_id = UUID.generate()
    l_id = UUID.generate()
    d_id_1 = UUID.generate()
    d_id_2 = UUID.generate()
    e_id_1 = UUID.generate()
    e_id_2 = UUID.generate()

    declarations = [
      %{
        "person_id" => p_id,
        "division_id" => d_id_1,
        "employee_id" => e_id_1,
        "legal_entity_id" => l_id
      },
      %{
        "person_id" => p_id,
        "division_id" => d_id_2,
        "employee_id" => e_id_2,
        "legal_entity_id" => l_id
      }
    ]

    ids = API.fetch_related_ids(declarations)
    assert ids["person_ids"] == [p_id]
    assert ids["legal_entity_ids"] == [l_id]
    assert ids["division_ids"] == [d_id_2, d_id_1]
    assert ids["employee_ids"] == [e_id_2, e_id_1]
  end

  test "build_indexes" do
    employees = []
    divisions = [%{"id" => "d-1"}]
    legal_entities = [%{"id" => "l-1"}, %{"id" => "l-2"}]
    persons = [%{"id" => "p-1"}, %{"id" => "p-2"}, %{"id" => "p-3"}]
    indexes = API.build_indexes(divisions, employees, legal_entities, persons)
    assert %{} == indexes.employees
    assert %{"d-1" => %{"id" => "d-1"}} == indexes.divisions
    assert %{"l-1" => %{"id" => "l-1"}, "l-2" => %{"id" => "l-2"}} == indexes.legal_entities
    assert %{"p-1" => %{"id" => "p-1"}, "p-2" => %{"id" => "p-2"}, "p-3" => %{"id" => "p-3"}} == indexes.persons
  end
end
