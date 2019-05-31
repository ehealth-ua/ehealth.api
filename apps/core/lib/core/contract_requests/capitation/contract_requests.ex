defmodule Core.CapitationContractRequests do
  @moduledoc false

  alias Core.ContractRequests.CapitationContractRequest
  use Core.ContractRequests, schema: CapitationContractRequest
  import Ecto.Query

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  def get_contract_requests_to_deactivate(legal_entity_id) do
    CapitationContractRequest
    |> select([cr], %{schema: "contract_request", entity: cr})
    |> where([cr], cr.type == ^CapitationContractRequest.type())
    |> where([cr], cr.contractor_legal_entity_id == ^legal_entity_id)
    |> where(
      [cr],
      cr.status in ^[
        CapitationContractRequest.status(:new),
        CapitationContractRequest.status(:in_process),
        CapitationContractRequest.status(:approved),
        CapitationContractRequest.status(:pending_nhs_sign),
        CapitationContractRequest.status(:nhs_signed)
      ]
    )
    |> @read_repo.all()
  end
end
