defmodule GraphQL.Unit.Dataloader.RpcTest do
  @moduledoc false

  use ExUnit.Case, async: false
  import Mox

  alias GraphQL.Dataloader.RPC, as: RpcDataloader
  alias Ecto.UUID

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    source = RpcDataloader.new("test_rpc", Test.RPC)
    loader = Dataloader.new() |> Dataloader.add_source(TestRPC, source)

    {:ok, loader: loader}
  end

  test "loads many entities", %{loader: loader} do
    entity_id = UUID.generate()
    entity = %{id: entity_id}

    entities =
      Enum.map(1..8, fn index ->
        parent_id = if index <= 3, do: entity_id, else: UUID.generate()

        %{id: UUID.generate(), parent_id: parent_id}
      end)

    expect(RPCWorkerMock, :run, fn _, _, _, _ ->
      {:ok, entities}
    end)

    batch_key = {:search_entities, :many, :parent_id, %{first: 10}}

    loaded_entities =
      loader
      |> Dataloader.load(TestRPC, batch_key, entity)
      |> Dataloader.run()
      |> Dataloader.get(TestRPC, batch_key, entity)

    assert 3 == length(loaded_entities)
  end

  test "loads one entity", %{loader: loader} do
    parent_id = UUID.generate()
    entity = %{id: UUID.generate(), parent_id: parent_id}

    expect(RPCWorkerMock, :run, fn _, _, _, _ ->
      {:ok, [%{id: parent_id}]}
    end)

    batch_key = {{:search_entities, :one, :parent_id, :id}, _args = %{}}

    loaded_entity =
      loader
      |> Dataloader.load(TestRPC, batch_key, entity)
      |> Dataloader.run()
      |> Dataloader.get(TestRPC, batch_key, entity)

    assert parent_id == loaded_entity.id
  end
end
