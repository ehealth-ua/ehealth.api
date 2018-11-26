defmodule GraphQLWeb.Resolvers.ContractResolver do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import Ecto.Query, only: [order_by: 2, order_by: 3, join: 4]
  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]
  import GraphQLWeb.Resolvers.Helpers.Search, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Contracts
  alias Core.Contracts.CapitationContract
  alias Core.PRMRepo
  alias GraphQLWeb.Loaders.IL
  alias GraphQLWeb.Loaders.PRM

  def list_contracts(args, %{context: %{client_type: "NHS"}}), do: list_contracts(args)

  def list_contracts(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    args
    |> Map.update!(:filter, &[{:contractor_legal_entity_id, client_id} | &1])
    |> list_contracts()
  end

  def list_contracts(%{filter: filter, order_by: order_by} = args) do
    filter = prepare_filter(filter)

    CapitationContract
    |> filter(filter)
    |> prepare_order_by(order_by)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end

  def get_attached_documents(%CapitationContract{} = parent, args, %{context: %{loader: loader}}) do
    source = IL
    batch_key = {CapitationContractRequest, args}
    item_key = parent.contract_request_id

    loader
    |> Dataloader.load(source, batch_key, item_key)
    |> on_load(fn loader ->
      with %CapitationContractRequest{id: id, status: _status} <- Dataloader.get(loader, source, batch_key, item_key),
           contract_documents when is_list(contract_documents) <- Contracts.gen_relevant_get_links(parent.id),
           contract_request_documents when is_list(contract_request_documents) <-
             ContractRequests.gen_relevant_get_links(id, "APPROVED") do
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

  defp prepare_filter([]), do: []
  defp prepare_filter([{:legal_entity_relation, relation} | tail]), do: [{relation, %{}} | prepare_filter(tail)]
  defp prepare_filter([head | tail]), do: [head | prepare_filter(tail)]

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
      err -> render_error(err)
    end
  end

  def prolongate(%{id: id, end_date: end_date}, %{context: %{headers: headers}}) do
    params = %{"end_date" => to_string(end_date)}

    with {:ok, contract, _} <- Contracts.prolongate(id, params, headers) do
      {:ok, %{contract: contract}}
    else
      err -> render_error(err)
    end
  end
end
