defmodule Core.ContractRequests.ReimbursementContractRequest do
  @moduledoc false

  alias Ecto.UUID

  @inheritance_name "REIMBURSEMENT"

  use Core.ContractRequests.ContractRequest,
    inheritance_name: @inheritance_name,
    fields: [
      {:medical_program_id, UUID}
    ]
end
