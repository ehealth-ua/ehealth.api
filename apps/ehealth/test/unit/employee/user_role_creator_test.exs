defmodule EHealth.Unit.Employee.UserRoleCreatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  alias EHealth.Employees.UserRoleCreator

  test "create/2" do
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
    party = insert(:prm, :party)
    user_id = "d0bde310-8401-11e7-bb31-be2e44b06b34"
    insert(:prm, :party_user, party: party, user_id: user_id)
    employee = insert(:prm, :employee, party: party, legal_entity: legal_entity)
    assert :ok == UserRoleCreator.create(employee, get_headers())
  end

  defp get_headers do
    [
      {"x-consumer-id", Ecto.UUID.generate()}
    ]
  end
end
