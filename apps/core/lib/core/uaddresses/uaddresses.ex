defmodule Core.Uaddresses do
  @moduledoc false

  @rpc_worker Application.get_env(:core, :rpc_worker)

  def list_settlements(filter, order_by \\ [], cursor \\ nil) do
    @rpc_worker.run("uaddresses", Uaddresses.Rpc, :search_settlements, [filter, order_by, cursor])
  end
end
