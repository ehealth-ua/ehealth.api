defmodule GraphQLWeb.Loaders.MPI do
  @moduledoc false

  alias GraphQLWeb.Dataloader.RPC, as: DataloaderRPC

  def data, do: DataloaderRPC.new("mpi")
end
