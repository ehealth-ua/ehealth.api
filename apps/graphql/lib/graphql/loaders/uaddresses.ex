defmodule GraphQL.Loaders.Uaddresses do
  @moduledoc false

  alias GraphQL.Dataloader.RPC, as: DataloaderRPC

  def data, do: DataloaderRPC.new("uaddresses_api", Uaddresses.Rpc)
end
