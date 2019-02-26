defmodule GraphQL.Filters.ContractRequests do
  @moduledoc false

  use EctoFilter
  use EctoFilter.Operators.JSON
  use GraphQL.Operators.DateInclusion

  alias Core.ContractRequests.{CapitationContractRequest, ReimbursementContractRequest}

  @allowed_contexts [CapitationContractRequest, ReimbursementContractRequest]
  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def apply(query, {field, nil, conditions} = operation, nil = type, context) when context in @allowed_contexts do
    case field in context.related_schemas() do
      true -> apply_related(query, context, field, conditions)
      false -> super(query, operation, type, context)
    end
  end

  def apply(query, operation, type, context), do: super(query, operation, type, context)

  defp apply_related(query, schema, field, conditions) do
    ids =
      field
      |> schema.related_schema()
      |> filter(conditions)
      |> select([r], r.id)
      |> @read_prm_repo.all()

    where(query, [..., r], field(r, ^:"#{field}_id") in ^ids)
  end
end
