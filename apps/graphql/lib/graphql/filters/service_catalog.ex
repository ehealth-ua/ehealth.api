defmodule GraphQL.Filters.ServiceCatalog do
  @moduledoc false

  use EctoFilter

  alias Core.Services.{Service, ServiceGroup}

  def apply(query, {:code, :like, value}, _, context) when context in [Service, ServiceGroup] do
    where(query, [..., r], ilike(r.code, ^"#{value}%"))
  end

  def apply(query, operation, type, context), do: super(query, operation, type, context)
end
