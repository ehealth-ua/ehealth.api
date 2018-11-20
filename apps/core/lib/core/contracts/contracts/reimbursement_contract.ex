defmodule Core.ContractRequests.ReimbursementContract do
  @moduledoc false

  alias Core.ContractRequests.ReimbursementContractRequest
  alias Ecto.UUID

  @contract_type ReimbursementContractRequest.type()

  use Core.Contracts.Contract,
    fields: [
      {:contract_type, :string, default: @contract_type},
      {:program_id, UUID}
    ]

  def type, do: @contract_type
end
