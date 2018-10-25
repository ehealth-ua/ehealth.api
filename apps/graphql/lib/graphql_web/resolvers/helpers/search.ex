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

      defp filter(query, [{field, value} | tail]) do
        query
        |> where([r], field(r, ^field) == ^value)
        |> filter(tail)
      end
    end
  end
end
