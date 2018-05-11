defmodule EHealth.Validators.Cache do
  @moduledoc false

  use Agent

  @behaviour EHealth.Validators.CacheBehaviour

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_json_schema(key) do
    Agent.get(__MODULE__, &{:ok, Map.get(&1, key)})
  end

  def set_json_schema(key, schema) do
    Agent.update(__MODULE__, &Map.put(&1, key, schema))
  end
end
