defmodule EHealth.Unit.DeclarationsTest do
  @moduledoc false

  use ExUnit.Case
  alias EHealth.Declarations.API
  alias Ecto.UUID

  test "fetch_related_ids" do
    p_id = UUID.generate()
    l_id = UUID.generate()
    d_id_1 = UUID.generate()
    d_id_2 = UUID.generate()
    e_id_1 = UUID.generate()
    e_id_2 = UUID.generate()

    declarations = [%{
      "person_id" => p_id,
      "division_id" => d_id_1,
      "employee_id" => e_id_1,
      "legal_entity_id" => l_id
    }, %{
      "person_id" => p_id,
      "division_id" => d_id_2,
      "employee_id" => e_id_2,
      "legal_entity_id" => l_id
    }]

    ids = API.fetch_related_ids(declarations)
    assert ids["person_ids"] == [p_id]
    assert ids["legal_entity_ids"] == [l_id]
    assert ids["division_ids"] == [d_id_2, d_id_1]
    assert ids["employee_ids"] == [e_id_2, e_id_1]

  end
end
