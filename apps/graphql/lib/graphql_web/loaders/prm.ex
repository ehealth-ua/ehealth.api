defmodule GraphQLWeb.Loaders.PRM do
  @moduledoc false

  import Ecto.Query, only: [where: 2, order_by: 2, limit: 2, offset: 2]

  alias Absinthe.Relay.Connection
  alias Core.PRMRepo

  def data, do: Dataloader.Ecto.new(PRMRepo, query: &query/2)

  def query(queryable, %{filter: filter, order_by: order_by} = args) do
    {:ok, :forward, limit} = Connection.limit(args)
    limit = limit + 1

    offset =
      case Connection.offset(args) do
        {:ok, offset} when is_integer(offset) -> offset
        _ -> 0
      end

    queryable
    |> where(^filter)
    |> order_by(^order_by)
    |> limit(^limit)
    |> offset(^offset)
  end

  def query(queryable, _), do: queryable
end
