defmodule EHealth.RpcTest do
  @moduledoc false

  use Core.ConnCase, async: true
  alias Core.PRMRepo
  alias Ecto.UUID
  alias EHealth.Rpc

  describe "service_by_id/1" do
    test "service not found" do
      refute Rpc.service_by_id(UUID.generate())
    end

    test "get service by id success" do
      service = insert(:prm, :service)

      id = service.id
      assert {:ok, %{id: ^id}} = Rpc.service_by_id(id)
    end
  end

  describe "service_group_by_id/1" do
    test "service group not found" do
      refute Rpc.service_group_by_id(UUID.generate())
    end

    test "get service group by id success" do
      service_group = insert(:prm, :service_group)

      id = service_group.id
      assert {:ok, %{id: ^id}} = Rpc.service_group_by_id(id)
    end
  end

  describe "service_belongs_to_group?/2" do
    test "service does not belong to group" do
      refute Rpc.service_belongs_to_group?(UUID.generate(), UUID.generate())
    end

    test "service belongs to group" do
      service = insert(:prm, :service)
      service_group = insert(:prm, :service_group)
      insert(:prm, :service_inclusion, service: service, service_group: service_group)

      assert Rpc.service_belongs_to_group?(service.id, service_group.id)
    end
  end

  describe "employees_by_user_id_client_id/2" do
    test "no employees by user_id, client_id" do
      refute Rpc.employees_by_user_id_client_id(UUID.generate(), UUID.generate())
    end

    test "get employees by user_id, client_id" do
      legal_entity = insert(:prm, :legal_entity)

      employee =
        :prm
        |> insert(:employee, legal_entity_id: legal_entity.id)
        |> PRMRepo.preload(:party)

      party_user = insert(:prm, :party_user, party: employee.party)
      assert {:ok, [_]} = Rpc.employees_by_user_id_client_id(party_user.user_id, legal_entity.id)
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

  describe "employee_by_id/1" do
    test "no employee found" do
      refute Rpc.employee_by_id(UUID.generate())
    end

    test "get employee by id" do
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity: legal_entity)

      id = employee.id
      assert {:ok, %{id: ^id}} = Rpc.employee_by_id(employee.id)
    end
  end

  describe "employee_by_id_users_short/1" do
    test "no employee found" do
      refute Rpc.employee_by_id(UUID.generate())
    end

    test "get employee by id with users short" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)

      employee =
        :prm
        |> insert(:employee, legal_entity_id: legal_entity_id)
        |> PRMRepo.preload(:party)

      id = employee.id
      insert(:prm, :party_user, party_id: employee.party_id)

      assert {:ok,
              %{
                id: ^id,
                legal_entity_id: ^legal_entity_id,
                party: %{
                  users: [_]
                }
              }} = Rpc.employee_by_id_users_short(id)
    end
  end

  describe "get_dictionaries/1" do
    test "success get dictionaries" do
      assert {:ok,
              [
                %{
                  is_active: true,
                  labels: ["SYSTEM"],
                  name: "KVEDS_ALLOWED_PHARMACY",
                  values: %{
                    "47.73" => "Роздрібна торгівля фармацевтичними товарами в спеціалізованих магазинах"
                  }
                }
              ]} = Rpc.get_dictionaries(%{})
    end
  end

  describe "legal_entity_by_id/1" do
    test "no legal entity found" do
      refute Rpc.legal_entity_by_id(UUID.generate())
    end

    test "get legal entity by id" do
      %{id: id} = insert(:prm, :legal_entity)
      assert {:ok, %{id: ^id}} = Rpc.legal_entity_by_id(id)
    end
  end

  describe "division_by_id/1" do
    test "no legal entity found" do
      refute Rpc.division_by_id(UUID.generate())
    end

    test "get legal entity by id" do
      %{id: id} = insert(:prm, :division)
      assert {:ok, %{id: ^id}} = Rpc.division_by_id(id)
    end
  end
end
