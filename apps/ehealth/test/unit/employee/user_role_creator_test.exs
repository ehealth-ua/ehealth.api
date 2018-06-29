defmodule EHealth.Unit.Employee.UserRoleCreatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias EHealth.Employees.UserRoleCreator
  alias Ecto.UUID

  test "create/2" do
    expect(MithrilMock, :get_roles_by_name, fn _, _ ->
      {:ok, %{"data" => []}}
    end)

    user_id = UUID.generate()
    legal_entity = insert(:prm, :legal_entity)

    expect(MithrilMock, :get_user_roles, fn _, _, _ ->
      {:ok, %{"data" => [%{"user_id" => user_id, "client_id" => legal_entity.id}]}}
    end)

    insert(:prm, :division)
    party = insert(:prm, :party)
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
