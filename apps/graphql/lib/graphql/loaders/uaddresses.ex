defmodule GraphQL.Loaders.Uaddresses do
  @moduledoc false

  alias GraphQL.Dataloader.RPC, as: DataloaderRPC

  def data, do: DataloaderRPC.new("uaddresses", Uaddresses.Rpc)
end
