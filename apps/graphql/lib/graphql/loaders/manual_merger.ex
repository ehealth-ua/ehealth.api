defmodule GraphQL.Loaders.ManualMerger do
  @moduledoc false

  alias GraphQL.Dataloader.RPC, as: DataloaderRPC

  def data, do: DataloaderRPC.new("manual_merger", ManualMerger.Rpc)
end
