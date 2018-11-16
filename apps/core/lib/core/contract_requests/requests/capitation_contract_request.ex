defmodule Core.ContractRequests.CapitationContractRequest do
  @moduledoc false

  @contract_type "CAPITATION"

  use Core.ContractRequests.ContractRequest,
    fields: [
      {:contract_type, :string, default: @contract_type},
      {:contractor_rmsp_amount, :integer},
      {:external_contractor_flag, :boolean, default: false},
      {:external_contractors, {:array, :map}},
      {:contractor_employee_divisions, {:array, :map}},
      {:nhs_contract_price, :float}
    ]

  def type, do: @contract_type
end
