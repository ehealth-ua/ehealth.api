defmodule GraphQLWeb.Loaders.Uaddresses do
  @moduledoc false

  alias GraphQLWeb.Dataloader.RPC, as: DataloaderRPC

  def data, do: DataloaderRPC.new("uaddresses", Uaddresses.Rpc)
end
