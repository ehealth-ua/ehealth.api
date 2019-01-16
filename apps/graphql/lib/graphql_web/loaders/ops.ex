defmodule GraphQLWeb.Loaders.OPS do
  @moduledoc false

  alias GraphQLWeb.Dataloader.RPC, as: DataloaderRPC

  def data, do: DataloaderRPC.new("ops")
end
