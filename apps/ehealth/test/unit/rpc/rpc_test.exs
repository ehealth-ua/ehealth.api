defmodule EHealth.RpcTest do
  @moduledoc false

  use Core.ConnCase, async: true
  alias EHealth.Rpc
  alias Ecto.UUID

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
      insert(:prm, :services_groups, service: service, service_group: service_group)

      assert Rpc.service_belongs_to_group?(service.id, service_group.id)
    end
  end
end
