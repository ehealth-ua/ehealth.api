defmodule Core.ContractRequests.ReimbursementContractRequest do
  @moduledoc false

  @contract_type "REIMBURSEMENT"

  use Core.ContractRequests.ContractRequest,
    fields: [
      {:contract_type, :string, default: @contract_type},
      {:program_id, Ecto.UUID}
    ]

  def type, do: @contract_type
end
