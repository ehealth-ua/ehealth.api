defmodule GraphQL.Resolvers.INNMDosage do
  @moduledoc false

  import GraphQL.Filters.Base, only: [filter: 2]
  import Ecto.Query, only: [order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.Medications.INNMDosage

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_innm_dosages(%{filter: filter, order_by: order_by} = args, _) do
    INNMDosage
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end
end
