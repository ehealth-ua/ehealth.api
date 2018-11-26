defmodule Core.API.RPCWorkerBehaviour do
  @moduledoc false

  @callback run(module :: atom, function :: atom, args :: list(), attempt :: integer, skip_servers :: list()) :: any()
end
