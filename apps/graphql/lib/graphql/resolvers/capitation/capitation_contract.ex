defmodule GraphQL.Resolvers.CapitationContract do
  @moduledoc false

  use GraphQL.Resolvers.Contract,
    schema: Core.Contracts.CapitationContract,
    request_schema: Core.ContractRequests.CapitationContractRequest,
    restricted_client_type: "MSP"

  alias Core.Contracts.Renderer
  alias Core.Dictionaries.Dictionary
  alias GraphQL.Loaders.PRM

  @consent_text_dictionary "CAPITATION_CONTRACT_CONSENT_TEXT"

  def load_contract_employees(parent, args, resolution) do
    load_by_parent_with_connection(parent, args, resolution, :contract_employees)
  end

  def get_to_create_request_content(parent, _, %{context: %{client_id: client_id, loader: loader}}) do
    loader
    |> Dataloader.load(PRM, :contract_divisions, parent)
    |> Dataloader.load(PRM, :contract_employees, parent)
    |> Dataloader.load(IL, {:one, Dictionary}, name: @consent_text_dictionary)
    |> on_load(fn loader ->
      with contract_divisions <- Dataloader.get(loader, PRM, :contract_divisions, parent),
           contract_employees <- Dataloader.get(loader, PRM, :contract_employees, parent),
           %Dictionary{values: values} <-
             Dataloader.get(loader, IL, {:one, Dictionary}, name: @consent_text_dictionary),
           {:ok, consent_text} <- Map.fetch(values, "APPROVED") do
        content =
          parent
          |> Map.put(:nhs_legal_entity_id, client_id)
          |> Renderer.render_create_request_content(%{
            consent_text: consent_text,
            contract_divisions: contract_divisions,
            contract_employees: contract_employees
          })

        {:ok, content}
      else
        _ -> {:error, :internal_server_error}
      end
    end)
  end
end
