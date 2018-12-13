defmodule GraphQLWeb.Resolvers.CapitationContractResolver do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import Ecto.Query, only: [where: 3]
  import GraphQLWeb.Resolvers.ContractResolver, only: [filter: 2, order_by: 2]
  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_parent_with_connection: 4]

  alias Absinthe.Relay.Connection
  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.Storage
  alias Core.PRMRepo
  alias GraphQLWeb.Loaders.IL

  @capitation CapitationContract.type()

  def list_contracts(args, %{context: %{client_type: "NHS"}}), do: list_contracts(args)

  def list_contracts(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    args
    |> Map.update!(:filter, &[{:contractor_legal_entity_id, :equal, client_id} | &1])
    |> list_contracts()
  end

  def list_contracts(%{filter: filter, order_by: order_by} = args) do
    CapitationContract
    |> where([c], c.type == @capitation)
    |> filter(filter)
    |> order_by(order_by)
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
           contract_documents when is_list(contract_documents) <- Storage.gen_relevant_get_links(parent.id),
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
end
