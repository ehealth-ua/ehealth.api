defmodule Core.ReimbursementContractRequests do
  @moduledoc false

  alias Core.ContractRequests.ReimbursementContractRequest
  use Core.ContractRequests, schema: ReimbursementContractRequest
  import Ecto.Query

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  def get_contract_requests_to_deactivate(legal_entity_id) do
    ReimbursementContractRequest
    |> select([cr], %{schema: "contract_request", entity: cr})
    |> where([cr], cr.type == ^ReimbursementContractRequest.type())
    |> where([cr], cr.contractor_legal_entity_id == ^legal_entity_id)
    |> where(
      [cr],
      cr.status in ^[
        ReimbursementContractRequest.status(:new),
        ReimbursementContractRequest.status(:in_process),
        ReimbursementContractRequest.status(:approved),
        ReimbursementContractRequest.status(:pending_nhs_sign),
        ReimbursementContractRequest.status(:nhs_signed)
      ]
    )
    |> @read_repo.all()
  end
end
