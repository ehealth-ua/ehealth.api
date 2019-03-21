defmodule GraphQL.Filters.Base do
  @moduledoc false

  use EctoFilter
  use EctoFilter.Operators.JSON
  use GraphQL.Operators.RangeInclusion

  alias Core.Parties.Party

  def apply(query, {_, nil, []}, :map, _), do: query

  def apply(query, {parent_field, nil, [{field, :like, value} | tail]}, :map = type, context) do
    query
    |> where([..., r], ilike(fragment("?->>?", field(r, ^parent_field), ^to_string(field)), ^"%#{value}%"))
    |> apply({parent_field, nil, tail}, type, context)
  end

  def apply(query, operation, type, context), do: super(query, operation, type, context)

  defoverridable EctoFilter

  def apply(query, {:full_name, :full_text_search, value}, _, Party) do
    where(
      query,
      [..., r],
      fragment(
        "to_tsvector(concat_ws(' ', ?, ?, ?)) @@ plainto_tsquery(?)",
        r.last_name,
        r.first_name,
        r.second_name,
        ^value
      )
    )
  end

  def apply(query, operation, type, context), do: super(query, operation, type, context)
end
