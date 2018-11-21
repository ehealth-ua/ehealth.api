defmodule Core.ContractRequests.ReimbursementContract do
  @moduledoc false

  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.MedicalPrograms.MedicalProgram
  alias Ecto.UUID

  @inheritance_name ReimbursementContractRequest.type()

  use Core.Contracts.Contract,
    inheritance_name: @inheritance_name,
    belongs_to: [
      {:medical_program, MedicalProgram, type: UUID}
    ]
end
