defmodule Core.RpcTest do
  @moduledoc false

  use Core.ConnCase, async: true
  alias Core.PRMRepo
  alias Core.Rpc
  alias Ecto.UUID

  describe "employees_by_user_id_client_id/2" do
    test "no employees by user_id, client_id" do
      assert [] = Rpc.employees_by_user_id_client_id(UUID.generate(), UUID.generate())
    end

    test "get employees by user_id, client_id" do
      legal_entity = insert(:prm, :legal_entity)

      employee =
        :prm
        |> insert(:employee, legal_entity_id: legal_entity.id)
        |> PRMRepo.preload(:party)

      party_user = insert(:prm, :party_user, party: employee.party)
      assert [_] = Rpc.employees_by_user_id_client_id(party_user.user_id, legal_entity.id)
    end
  end

  describe "employees_by_party_id_client_id/2" do
    test "no employees by party_id, client_id" do
      assert [] = Rpc.employees_by_party_id_client_id(UUID.generate(), UUID.generate())
    end

    test "get employees by party_id, client_id" do
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity_id: legal_entity.id)
      assert [_] = Rpc.employees_by_party_id_client_id(employee.party_id, legal_entity.id)
    end
  end

  describe "tax_id_by_employee_id/1" do
    test "no employee found" do
      refute Rpc.tax_id_by_employee_id(UUID.generate())
    end

    test "get tax_id by employee_id" do
      employee =
        :prm
        |> insert(:employee)
        |> PRMRepo.preload(:party)

      tax_id = employee.party.tax_id
      assert ^tax_id = Rpc.tax_id_by_employee_id(employee.id)
    end
  end
end
