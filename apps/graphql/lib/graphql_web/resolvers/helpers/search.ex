defmodule GraphQLWeb.Resolvers.Helpers.Search do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      import Ecto.Query, only: [where: 3, order_by: 2]

      @spec search(Ecto.Query.t(), map) :: Ecto.Query.t()
      def search(query, %{filter: filter, order_by: order_by} = _args) do
        query
        |> filter(filter)
        |> order_by(^order_by)
      end

      defp filter(query, []), do: query

      defp filter(query, [{field, %{first: %Date{} = first, last: %Date{} = last}} | tail]) do
        query
        |> where([r], fragment("? <@ daterange(?, ?, '[]')", field(r, ^field), ^first, ^last))
        |> filter(tail)
      end

      defp filter(query, [{field, %{first: %Date{} = first}} | tail]) do
        query
        |> where([r], fragment("? <@ daterange(?, 'infinity', '[)')", field(r, ^field), ^first))
        |> filter(tail)
      end

      defp filter(query, [{field, %{last: %Date{} = last}} | tail]) do
        query
        |> where([r], fragment("? <@ daterange('infinity', ?, '(]')", field(r, ^field), ^last))
        |> filter(tail)
      end

      defp filter(query, [%{first: _, last: _} | tail]), do: filter(query, tail)

      defp filter(query, [{field, value} | tail]) do
        query
        |> where([r], field(r, ^field) == ^value)
        |> filter(tail)
      end
    end
  end
end
