defmodule GraphQL.Resolvers.CapitationContract do
  @moduledoc false

  use GraphQL.Resolvers.Contract,
    schema: Core.Contracts.CapitationContract,
    request_schema: Core.ContractRequests.CapitationContractRequest,
    restricted_client_type: "MSP"

  alias Core.Contracts.Renderer
  alias GraphQL.Loaders.PRM

  def load_contract_employees(parent, args, resolution) do
    load_by_parent_with_connection(parent, args, resolution, :contract_employees)
  end

  def get_to_create_request_content(parent, _, %{context: %{client_id: client_id, loader: loader}}) do
    loader
    |> Dataloader.load(PRM, :contract_divisions, parent)
    |> Dataloader.load(PRM, :contract_employees, parent)
    |> on_load(fn loader ->
      contract_divisions = Dataloader.get(loader, PRM, :contract_divisions, parent)
      contract_employees = Dataloader.get(loader, PRM, :contract_employees, parent)

      content =
        parent
        |> Map.put(:nhs_legal_entity_id, client_id)
        |> Renderer.render_create_request_content(%{
          contract_divisions: contract_divisions,
          contract_employees: contract_employees
        })

      {:ok, content}
    end)
  end
end
