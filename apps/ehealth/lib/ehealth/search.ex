defmodule EHealth.Search do
  @moduledoc """
  Search implementation
  """

  defmacro __using__(repo) do
    quote do
      import Ecto.{Query, Changeset}, warn: false

      def search(%Ecto.Changeset{valid?: true, changes: changes}, search_params, entity) do
        repo = unquote(repo)

        entity
        |> get_search_query(changes)
        |> repo.paginate(search_params)
      end

      def search(%Ecto.Changeset{valid?: false} = changeset, _search_params, _entity) do
        {:error, changeset}
      end

      def get_search_query(entity, changes) when map_size(changes) > 0 do
        params = Enum.filter(changes, fn {_key, value} -> !is_tuple(value) end)

        q = where(entity, ^params)

        Enum.reduce(changes, q, fn {key, val}, query ->
          case val do
            {value, :like} -> where(query, [r], ilike(field(r, ^key), ^("%" <> value <> "%")))
            {value, :in} -> where(query, [r], field(r, ^key) in ^value)
            {value, :json_list} -> where(query, [r], fragment("? @> ?", field(r, ^key), ^value))
            _ -> query
          end
        end)
      end

      def get_search_query(entity, _changes), do: from(e in entity)

      def to_integer(value) when is_binary(value), do: String.to_integer(value)
      def to_integer(value), do: value

      defoverridable get_search_query: 2
    end
  end
end
