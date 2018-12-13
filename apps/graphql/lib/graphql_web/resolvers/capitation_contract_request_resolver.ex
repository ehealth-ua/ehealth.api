defmodule GraphQLWeb.Resolvers.CapitationContractRequestResolver do
  @moduledoc false

  import Ecto.Query, only: [where: 3, join: 4, select: 3, order_by: 2]
  import GraphQLWeb.Resolvers.Helpers.Search, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.{PRMRepo, Repo}

  @capitation CapitationContractRequest.type()

  def list_contract_requests(args, %{context: %{client_type: "NHS"}}), do: list_contract_requests(args)

  def list_contract_requests(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    args
    |> Map.update!(:filter, &[{:contractor_legal_entity_id, client_id} | &1])
    |> list_contract_requests()
  end

  defp list_contract_requests(%{filter: filter, order_by: order_by} = args) do
    filter = prepare_filter(filter)

    CapitationContractRequest
    |> where([c], c.type == @capitation)
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&Repo.all/1, args)
  end

  defp prepare_filter([]), do: []

  defp prepare_filter([{:contractor_legal_entity_edrpou, value} | tail]) do
    contractor_legal_entity_ids =
      LegalEntity
      |> where([l], l.edrpou == ^value)
      |> select([l], l.id)
      |> PRMRepo.all()

    [{:contractor_legal_entity_id, contractor_legal_entity_ids} | prepare_filter(tail)]
  end

  defp prepare_filter([{:assignee_name, value} | tail]) do
    assignee_ids =
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

    [{:assignee_id, assignee_ids} | prepare_filter(tail)]
  end

  defp prepare_filter([head | tail]), do: [head | prepare_filter(tail)]
end
