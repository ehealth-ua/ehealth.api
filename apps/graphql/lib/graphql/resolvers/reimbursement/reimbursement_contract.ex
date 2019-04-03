defmodule GraphQL.Resolvers.ReimbursementContract do
  @moduledoc false

  use GraphQL.Resolvers.Contract,
    schema: Core.Contracts.ReimbursementContract,
    request_schema: Core.ContractRequests.ReimbursementContractRequest,
    restricted_client_type: "PHARMACY"

  alias Core.Contracts.Renderer
  alias GraphQL.Loaders.PRM

  def get_to_create_request_content(parent, _, %{context: %{client_id: client_id, loader: loader}}) do
    loader
    |> Dataloader.load(PRM, :contract_divisions, parent)
    |> on_load(fn loader ->
      contract_divisions = Dataloader.get(loader, PRM, :contract_divisions, parent)

      content =
        parent
        |> Map.put(:nhs_legal_entity_id, client_id)
        |> Renderer.render_create_request_content(%{
          contract_divisions: contract_divisions
        })

      {:ok, content}
    end)
  end
end
