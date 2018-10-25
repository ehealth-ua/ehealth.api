defmodule GraphQLWeb.Loaders.IL do
  @moduledoc false

  import Ecto.Query, only: [where: 2]

  alias Core.ContractRequests.ContractRequest
  alias Core.Repo

  def data, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(ContractRequest, %{client_type: "MSP", client_id: client_id}) do
    where(ContractRequest, contractor_legal_entity_id: ^client_id)
  end

  def query(ContractRequest, %{client_type: "NHS"}), do: ContractRequest

  def query(queryable, _), do: queryable
end
