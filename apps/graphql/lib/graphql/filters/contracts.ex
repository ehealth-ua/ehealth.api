defmodule GraphQL.Filters.Contracts do
  @moduledoc false

  use EctoFilter
  use EctoFilter.Operators.JSON
  use GraphQL.Operators.RangeInclusion

  alias Core.Contracts.{CapitationContract, ReimbursementContract}

  @legal_entity_relations ~w(merged_from merged_to)a
  @allowed_contexts [CapitationContract, ReimbursementContract]

  def apply(query, {:legal_entity_relation, :equal, value}, _, context)
      when value in @legal_entity_relations and context in @allowed_contexts do
    query
    |> join(:inner, [r], assoc(r, ^value))
    |> where([..., m], m.is_active)
  end

  def apply(query, operation, type, context), do: super(query, operation, type, context)
end
