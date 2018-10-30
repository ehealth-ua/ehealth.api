defmodule GraphQLWeb.Resolvers.Helpers.Search do
  @moduledoc false

  import Ecto.Query, only: [where: 3, order_by: 2]

  @spec search(Ecto.Query.t(), map) :: Ecto.Query.t()
  def search(query, %{filter: filter, order_by: order_by} = _args) do
    query
    |> filter(filter)
    |> order_by(^order_by)
  end

  defp filter(query, []), do: query

  defp filter(query, [{field, %Date.Interval{first: %Date{} = first, last: %Date{} = last}} | tail]) do
    query
    |> where([r], fragment("? <@ daterange(?, ?, '[]')", field(r, ^field), ^first, ^last))
    |> filter(tail)
  end

  defp filter(query, [{field, %Date.Interval{first: %Date{} = first}} | tail]) do
    query
    |> where([r], fragment("? <@ daterange(?, 'infinity', '[)')", field(r, ^field), ^first))
    |> filter(tail)
  end

  defp filter(query, [{field, %Date.Interval{last: %Date{} = last}} | tail]) do
    query
    |> where([r], fragment("? <@ daterange('infinity', ?, '(]')", field(r, ^field), ^last))
    |> filter(tail)
  end

  defp filter(query, [%Date.Interval{} | tail]), do: filter(query, tail)

  defp filter(query, [{field, value} | tail]) do
    query
    |> where([r], field(r, ^field) == ^value)
    |> filter(tail)
  end
end
