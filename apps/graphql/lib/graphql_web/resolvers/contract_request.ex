defmodule GraphQLWeb.Resolvers.ContractRequest do
  @moduledoc false

  import Ecto.Query, only: [where: 2]
  import GraphQLWeb.Resolvers.Helpers, only: [search: 2]

  alias Absinthe.Relay.Connection
  alias Core.ContractRequests.ContractRequest
  alias Core.Repo

  def list_contract_requests(args, %{context: %{client_type: "NHS"}}) do
    ContractRequest
    |> search(args)
    |> Connection.from_query(&Repo.all/1, args)
  end

  def list_contract_requests(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    ContractRequest
    |> where(contractor_legal_entity_id: ^client_id)
    |> search(args)
    |> Connection.from_query(&Repo.all/1, args)
  end
end
