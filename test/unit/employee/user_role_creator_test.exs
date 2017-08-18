defmodule EHealth.Unit.Employee.UserRoleCreatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  alias EHealth.Employee.UserRoleCreator

  test "create/2" do
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
    employee_request_params =
      "test/data/employee_request.json"
      |> File.read!()
      |> Poison.decode!
    party = insert(:prm, :party)
    user_id = "d0bde310-8401-11e7-bb31-be2e44b06b34"
    insert(:prm, :party_user, party: party, user_id: user_id)
    params =
      employee_request_params
      |> Map.put("data", employee_request_params["employee_request"])
      |> put_in(["data", "party_id"], party.id)
      |> put_in(["data", "legal_entity_id"], legal_entity.id)
    assert {:ok, params} == UserRoleCreator.create({:ok, params}, get_headers())
  end

  defp get_headers do
    [
      {"x-consumer-id", Ecto.UUID.generate()}
    ]
  end
end
