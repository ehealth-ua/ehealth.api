defmodule Casher.Unit.RedisTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Casher.Redis

  test "get/set" do
    assert {:error, :not_found} = Redis.get("unknown_key")

    entity = %{value: 123}
    assert :ok = Redis.set("entity_key", entity)
    assert {:ok, ^entity} = Redis.get("entity_key")
  end

  test "set with ttl" do
    assert :ok = Redis.setex("key_with_ttl", 1, %{})

    :timer.sleep(500)
    assert {:ok, _} = Redis.get("key_with_ttl")

    :timer.sleep(600)
    assert {:error, :not_found} = Redis.get("key_with_ttl")
  end

  test "delete" do
    assert :ok = Redis.set("key", "some_value")
    assert {:ok, 1} = Redis.del("key")
    assert {:ok, 0} = Redis.del("unknown_key")
  end

  test "flush" do
    assert :ok = Redis.set("key", "some_value")
    assert :ok = Redis.flushdb()
    assert {:error, :not_found} = Redis.get("key")
  end
end
