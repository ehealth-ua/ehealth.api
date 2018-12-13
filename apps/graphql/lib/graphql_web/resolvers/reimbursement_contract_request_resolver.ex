defmodule GraphQLWeb.Resolvers.ReimbursementContractRequestResolver do
  @moduledoc false

  import Ecto.Query, only: [where: 3, join: 4, select: 3, order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Employees.Employee
  alias Core.{PRMRepo, Repo}
  alias GraphQL.Helpers.Filtering

  @reimbursement ReimbursementContractRequest.type()
  @related_schemas ReimbursementContractRequest.related_schemas()

  def list_contract_requests(args, %{context: %{client_type: "NHS"}}),
    do: list_contract_requests(args)

  def list_contract_requests(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    args
    |> Map.update!(:filter, &[{:contractor_legal_entity_id, :equal, client_id} | &1])
    |> list_contract_requests()
  end

  defp list_contract_requests(%{filter: filter, order_by: order_by} = args) do
    ReimbursementContractRequest
    |> where([c], c.type == @reimbursement)
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&Repo.all/1, args)
  end

  defp filter(query, [{:assignee_name, :full_text_search, value} | tail]) do
    ids =
      Employee
      |> join(:inner, [e], p in assoc(e, :party))
      |> where([e], e.employee_type in ~w(NHS NHS_SIGNER))
      |> where(
        [..., p],
        fragment(
          "to_tsvector(concat_ws(' ', ?, ?, ?)) @@ plainto_tsquery(?)",
          p.last_name,
          p.first_name,
          p.second_name,
          ^value
        )
      )
      |> select([e], e.id)
      |> PRMRepo.all()

    filter(query, [{:assignee_id, :in, ids} | tail])
  end

  defp filter(query, [{field, nil, conditions} | tail]) when field in @related_schemas do
    ids =
      field
      |> ReimbursementContractRequest.related_schema()
      |> Filtering.filter(conditions)
      |> select([r], r.id)
      |> PRMRepo.all()

    filter(query, [{:"#{field}_id", :in, ids} | tail])
  end

  defp filter(query, condition), do: Filtering.filter(query, condition)
end
