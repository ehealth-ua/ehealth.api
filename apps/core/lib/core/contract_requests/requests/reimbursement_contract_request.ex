defmodule Core.ContractRequests.ReimbursementContractRequest do
  @moduledoc false

  alias Ecto.UUID

  @contract_type "REIMBURSEMENT"

  use Core.ContractRequests.ContractRequest,
    fields: [
      {:contract_type, :string, default: @contract_type},
      {:program_id, UUID}
    ]

  def type, do: @contract_type
end
