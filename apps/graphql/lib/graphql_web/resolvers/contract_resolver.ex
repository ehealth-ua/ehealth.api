defmodule GraphQLWeb.Resolvers.ContractResolver do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import Ecto.Query, only: [order_by: 2, order_by: 3, join: 4]
  import GraphQLWeb.Resolvers.Helpers.Errors

  alias Absinthe.Relay.Connection
  alias Core.ContractRequests
  alias Core.ContractRequests.ContractRequest
  alias Core.Contracts
  alias Core.Contracts.Contract
  alias Core.PRMRepo
  alias GraphQLWeb.Loaders.IL
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
    |> prepare_order_by(order_by)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end

  def get_attached_documents(%Contract{} = parent, args, %{context: %{loader: loader}}) do
    source = IL
    batch_key = {ContractRequest, args}
    item_key = parent.contract_request_id

    loader
    |> Dataloader.load(source, batch_key, item_key)
    |> on_load(fn loader ->
      with %ContractRequest{id: id, status: status} <- Dataloader.get(loader, source, batch_key, item_key),
           contract_documents when is_list(contract_documents) <- Contracts.gen_relevant_get_links(parent.id, status),
           contract_request_documents when is_list(contract_request_documents) <-
             ContractRequests.gen_relevant_get_links(id, status) do
        {:ok, contract_documents ++ contract_request_documents}
      else
        nil -> {:error, "Contract request not found"}
        err -> {:error, "Cannot get attachedDocuments with `#{inspect(err)}`"}
      end
    end)
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

  defp prepare_order_by(query, [{direction, :contractor_legal_entity_edrpou}]) do
    query
    |> join(:inner, [c], le in assoc(c, :contractor_legal_entity))
    |> order_by([..., le], [{^direction, le.edrpou}])
  end

  defp prepare_order_by(query, order_by), do: order_by(query, ^order_by)

  def terminate(%{id: id, status_reason: status_reason}, %{context: %{headers: headers}}) do
    with {:ok, contract, _references} <- Contracts.terminate(id, %{"status_reason" => status_reason}, headers) do
      {:ok, %{contract: contract}}
    else
      # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
      # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
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

  def prolongate(%{id: id, end_date: end_date}, %{context: %{headers: headers}}) do
    params = %{"end_date" => to_string(end_date)}

    with {:ok, contract, _} <- Contracts.prolongate(id, params, headers) do
      {:ok, %{contract: contract}}
    else
      # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
      # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
      {:error, {:forbidden, error}} ->
        {:error, format_forbidden_error(error)}

      {:error, {:conflict, error}} ->
        {:error, format_conflict_error(error)}

      {:error, {:"422", error}} ->
        {:error, format_unprocessable_entity_error(error)}

      {:error, [_ | _] = errors} ->
        {:error, format_unprocessable_entity_error(errors)}

      error ->
        error
    end
  end
end
