defmodule GraphQLWeb.Loaders.PRM do
  @moduledoc false

  import Ecto.Query

  alias Absinthe.Relay.Connection
  alias Core.Contracts.Contract
  alias Core.Employees.Employee
  alias Core.PRMRepo

  def data, do: Dataloader.Ecto.new(PRMRepo, query: &query/2)

  def query(Contract, %{client_type: "MSP", client_id: client_id}) do
    where(Contract, contractor_legal_entity_id: ^client_id)
  end

  def query(Employee, %{client_type: "MSP", client_id: client_id}) do
    where(Employee, legal_entity_id: ^client_id)
  end

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

  defp prepare_where(query, [{:merged_from_legal_entity, filter} | tail]) do
    prepare_where(query, [merged_from: filter] ++ tail)
  end

  defp prepare_where(query, [{field, filter} | tail]) when is_map(filter) do
    query
    |> join(:inner, [r], assoc(r, ^field))
    |> prepare_where(Enum.into(filter, []))
    |> prepare_where(tail)
  end

  defp prepare_where(query, [{:database_id, value} | tail]) do
    prepare_where(query, [id: value] ++ tail)
  end

  defp prepare_where(query, [{field, {:like, value}} | tail]) do
    query
    |> where([..., l], ilike(field(l, ^field), ^("%" <> value <> "%")))
    |> prepare_where(tail)
  end

  defp prepare_where(query, [{field, value} | tail]) do
    query
    |> where([..., l], field(l, ^field) == ^value)
    |> prepare_where(tail)
  end
end
