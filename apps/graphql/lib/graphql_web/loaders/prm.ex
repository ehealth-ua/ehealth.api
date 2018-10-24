defmodule GraphQLWeb.Loaders.PRM do
  @moduledoc false

  import Ecto.Query, only: [where: 2, order_by: 2, limit: 2, offset: 2]

  alias Absinthe.Relay.Connection
  alias Core.PRMRepo

  def data, do: Dataloader.Ecto.new(PRMRepo, query: &query/2)

  def query(queryable, %{filter: filter, order_by: order_by} = args) do
    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
      limit = limit + 1

      queryable
      |> where(^filter)
      |> order_by(^order_by)
      |> limit(^limit)
      |> offset(^offset)
    end
  end

  def query(queryable, _), do: queryable
end
