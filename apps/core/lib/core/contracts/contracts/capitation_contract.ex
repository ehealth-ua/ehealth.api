defmodule Core.Contracts.CapitationContract do
  @moduledoc false

  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Contracts.ContractEmployee

  @contract_type CapitationContractRequest.type()

  use Core.Contracts.Contract,
    fields: [
      {:contract_type, :string, default: @contract_type},
      {:contractor_rmsp_amount, :integer},
      {:external_contractor_flag, :boolean},
      {:external_contractors, {:array, :map}},
      {:nhs_contract_price, :float}
    ],
    has_many: [
      {:contract_employees, ContractEmployee, foreign_key: :contract_id},
      {:contract_employees_divisions, [through: [:contract_employees, :division]], []}
    ]

  def type, do: @contract_type
end
