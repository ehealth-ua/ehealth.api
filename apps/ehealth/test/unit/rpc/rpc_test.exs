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
end
