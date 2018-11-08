defmodule GraphQLWeb.Resolvers.ContractResolver do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import Ecto.Query, only: [order_by: 2, join: 4]
  import GraphQLWeb.Resolvers.Helpers.Errors

  alias Absinthe.Relay.Connection
  alias Core.Contracts
  alias Core.Contracts.Contract
  alias Core.PRMRepo
  alias GraphQLWeb.Loaders.PRM
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

  def load_contract_divisions(parent, args, resolution) do
    load_by_parent_with_connection(parent, args, resolution, :divisions)
  end

  def load_contract_employees(parent, args, resolution) do
    load_by_parent_with_connection(parent, args, resolution, :contract_employees)
  end

  # ToDo: move to Resolvers.Helpers.Load
  def load_by_parent_with_connection(parent, args, %{context: %{loader: loader}} = resolution, resource) do
    resource = resource || resolution.definition.schema_node.identifier

    loader
    |> Dataloader.load(PRM, {resource, args}, parent)
    |> on_load(fn loader ->
      with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
        records = Dataloader.get(loader, PRM, {resource, args}, parent)
        opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

        Connection.from_slice(Enum.take(records, limit), offset, opts)
      end
    end)
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
