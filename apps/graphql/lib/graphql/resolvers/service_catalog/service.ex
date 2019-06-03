defmodule GraphQL.Resolvers.Service do
  @moduledoc false

  import Ecto.Query, only: [order_by: 2]
  import GraphQL.Filters.ServiceCatalog, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Services.Service

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_services(%{filter: filter, order_by: order_by} = args, _context) do
    Service
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end
end
