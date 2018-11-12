defmodule GraphQLWeb.Resolvers.Helpers.Search do
  @moduledoc false

  import Ecto.Query, only: [where: 3, join: 4, order_by: 2]

  @spec search(Ecto.Query.t(), map) :: Ecto.Query.t()
  def search(query, %{filter: filter, order_by: order_by} = _args) do
    query
    |> filter(filter)
    |> order_by(^order_by)
  end

  @spec filter(Ecto.Query.t(), list) :: Ecto.Query.t()
  def filter(query, expr)

  def filter(query, []), do: query

  def filter(query, [{field, %Date.Interval{first: %Date{} = first, last: %Date{} = last}} | tail]) do
    query
    |> where([..., r], fragment("? <@ daterange(?, ?, '[]')", field(r, ^field), ^first, ^last))
    |> filter(tail)
  end

  def filter(query, [{field, %Date.Interval{first: %Date{} = first}} | tail]) do
    query
    |> where([..., r], fragment("? <@ daterange(?, 'infinity', '[)')", field(r, ^field), ^first))
    |> filter(tail)
  end

  def filter(query, [{field, %Date.Interval{last: %Date{} = last}} | tail]) do
    query
    |> where([..., r], fragment("? <@ daterange('infinity', ?, '(]')", field(r, ^field), ^last))
    |> filter(tail)
  end

  def filter(query, [{:database_id, value} | tail]), do: filter(query, [{:id, value} | tail])

  def filter(query, [{field, value} | tail]) when is_list(value) do
    query
    |> where([..., r], field(r, ^field) in ^value)
    |> filter(tail)
  end

  def filter(query, [{field, value} | tail]) when is_map(value) do
    query
    |> filter(tail)
    |> join(:inner, [r], assoc(r, ^field))
    |> filter(Map.to_list(value))
  end

  def filter(query, [{field, {:ilike, value}} | tail]) do
    query
    |> where([..., r], ilike(field(r, ^field), ^value))
    |> filter(tail)
  end

  def filter(query, [{_field, {:fragment, {:contain, fragment_field, condition}}} | tail]) do
    query
    |> where([l], fragment("? @> ?", field(l, ^fragment_field), ^condition))
    |> filter(tail)
  end

  def filter(query, [{field, value} | tail]) do
    query
    |> where([..., r], field(r, ^field) == ^value)
    |> filter(tail)
  end
end
