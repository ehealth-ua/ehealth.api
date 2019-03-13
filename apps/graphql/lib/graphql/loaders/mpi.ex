defmodule GraphQL.Loaders.MPI do
  @moduledoc false

  alias GraphQL.Dataloader.RPC, as: DataloaderRPC

  def data, do: DataloaderRPC.new("mpi", MPI.Rpc)
end
