defmodule GraphQLWeb.Loaders.PRM do
  @moduledoc false

  import Ecto.Query

  alias Absinthe.Relay.Connection
  alias Core.PRMRepo

  def data, do: Dataloader.Ecto.new(PRMRepo, query: &query/2)

  def query(queryable, %{filter: filter, order_by: order_by} = args) do
    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
      limit = limit + 1

      queryable
      |> prepare_where(filter)
      |> order_by(^order_by)
      |> limit(^limit)
      |> offset(^offset)
    end
  end

  def query(queryable, _), do: queryable

  defp prepare_where(query, []), do: query

  defp prepare_where(query, [{:merged_from_legal_entity, filter} | _tail]) do
    query
    |> join(:left, [e], m in assoc(e, :merged_from))
    |> prepare_where(Enum.into(filter, []))
  end

  defp prepare_where(query, [{field, value} | tail]) do
    query
    |> where([..., l], field(l, ^field) == ^value)
    |> prepare_where(tail)
  end
end
