defmodule GraphQLWeb.Loaders.IL do
  @moduledoc false

  import Ecto.Query, only: [where: 2]

  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Repo

  def data, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(CapitationContractRequest, %{client_type: "MSP", client_id: client_id}) do
    where(CapitationContractRequest, contractor_legal_entity_id: ^client_id)
  end

  def query(CapitationContractRequest, %{client_type: "NHS"}), do: CapitationContractRequest

  def query(queryable, _), do: queryable
end
