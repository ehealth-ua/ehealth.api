defmodule Core.Validators.Cache do
  @moduledoc false

  use GenServer

  @behaviour Core.Validators.CacheBehaviour

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(state) do
    :ets.new(__MODULE__, [:set, :public, :named_table])
    {:ok, state}
  end

  @impl true
  def get_json_schema(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, schema}] -> {:ok, schema}
      _ -> {:ok, nil}
    end
  end

  @impl true
  def set_json_schema(key, schema) do
    :ets.insert(__MODULE__, {key, schema})
    :ok
  end
end
