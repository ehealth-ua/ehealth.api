defmodule GraphQLWeb.Resolvers.ContractResolver do
  @moduledoc false

  import Ecto.Query, only: [order_by: 2, join: 4]
  import GraphQLWeb.Resolvers.Helpers.Errors

  alias Absinthe.Relay.Connection
  alias Core.Contracts
  alias Core.Contracts.Contract
  alias Core.PRMRepo
  alias GraphQLWeb.Resolvers.Helpers.Search

  def list_contracts(args, %{context: %{client_type: "NHS"}}), do: list_contracts(args)

  def list_contracts(%{filter: filter} = args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    args
    |> Map.put(:filter, filter ++ [contractor_legal_entity_id: client_id])
    |> list_contracts()
  end

  def list_contracts(%{filter: filter, order_by: order_by} = args) do
    Contract
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end

  def filter(query, [{:legal_entity_relation, relation} | tail]) do
    query
    |> join(:inner, [c], r in assoc(c, ^relation))
    |> filter(tail)
  end

  def filter(query, args), do: Search.filter(query, args)

  def terminate(%{id: id, status_reason: status_reason}, %{context: %{headers: headers}}) do
    with {:ok, contract, _references} <- Contracts.terminate(id, %{"status_reason" => status_reason}, headers) do
      {:ok, %{contract: contract}}
    else
      # TODO: Remove after error handling is done
      {:error, {:forbidden, error}} ->
        {:error, format_forbidden_error(error)}

      {:error, {:conflict, error}} ->
        {:error, format_conflict_error(error)}

      {:error, {:not_found, error}} ->
        {:error, format_not_found_error(error)}

      error ->
        error
    end
  end
end
