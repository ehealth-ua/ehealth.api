defmodule GraphQL.Resolvers.ProgramService do
  @moduledoc false

  import Ecto.Query, only: [order_by: 2]
  import GraphQL.Filters.ServiceCatalog, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Services.ProgramService

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_program_services(%{filter: filter, order_by: order_by} = args, _) do
    ProgramService
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end
end
