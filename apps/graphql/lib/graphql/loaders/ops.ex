defmodule GraphQL.Loaders.OPS do
  @moduledoc false

  alias GraphQL.Dataloader.RPC, as: DataloaderRPC

  def data, do: DataloaderRPC.new("ops", OPS.Rpc)
end
