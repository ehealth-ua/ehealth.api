defmodule GraphQL.Filters.EmployeeRequests do
  @moduledoc false

  use EctoFilter
  use EctoFilter.Operators.JSON
  use GraphQL.Operators.RangeInclusion

  alias Core.EmployeeRequests.EmployeeRequest

  def apply(query, {:legal_entity_id, :equal, value}, _, EmployeeRequest) do
    where(query, [er], fragment("?->>'legal_entity_id' = ?", er.data, ^value))
  end

  def apply(query, {:email, :equal, value}, _, EmployeeRequest) do
    where(query, [er], fragment("?->'party'->>'email' = ?", er.data, ^value))
  end

  def apply(query, operation, type, context), do: super(query, operation, type, context)
end
