defmodule EHealth.PRM.Search do
  @moduledoc """
  Search implementation
  """

  defmacro __using__(_) do
    quote  do
      import Ecto.{Query, Changeset}, warn: false

      alias EHealth.PRMRepo

      def search(%Ecto.Changeset{valid?: true, changes: changes}, search_params, entity, default_limit) do
        limit =
          search_params
          |> Map.get("limit", default_limit)
          |> to_integer()

        cursors = %Ecto.Paging.Cursors{
          starting_after: Map.get(search_params, "starting_after"),
          ending_before: Map.get(search_params, "ending_before")
        }

        entity
        |> get_search_query(changes)
        |> PRMRepo.page(%Ecto.Paging{limit: limit, cursors: cursors})
      end

      def search(%Ecto.Changeset{valid?: false} = changeset, _search_params, _entity, _default_limit) do
        {:error, changeset}
      end

      def get_search_query(entity, changes) when map_size(changes) > 0 do
        params = Enum.filter(changes, fn({key, value}) -> !is_tuple(value) end)

        q = from e in entity,
          where: ^params

        Enum.reduce(changes, q, fn({key, val}, query) ->
          case val do
            {value, :like} -> where(query, [r], ilike(field(r, ^key), ^("%" <> value <> "%")))
            {value, :in} -> where(query, [r], field(r, ^key) in ^value)
            _ -> query
          end
        end)
      end
      def get_search_query(entity, _changes), do: from e in entity

      def to_integer(value) when is_binary(value), do: String.to_integer(value)
      def to_integer(value), do: value

      defoverridable [get_search_query: 2]
    end
  end
end
