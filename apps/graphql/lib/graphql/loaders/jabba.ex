defmodule GraphQL.Loaders.Jabba do
  @moduledoc false

  alias GraphQL.Dataloader.RPC, as: DataloaderRPC
  alias Jobs.Jabba.Client

  @pod Client.rpc_pod_name()

  def data, do: DataloaderRPC.new(@pod, Jabba.RPC)
end
