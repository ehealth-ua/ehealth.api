defmodule Core.ContractRequests.CapitationContractRequest do
  @moduledoc false

  @inheritance_name "CAPITATION"

  use Core.ContractRequests.ContractRequest,
    inheritance_name: @inheritance_name,
    fields: [
      {:contractor_rmsp_amount, :integer},
      {:external_contractor_flag, :boolean, default: false},
      {:external_contractors, {:array, :map}},
      {:contractor_employee_divisions, {:array, :map}},
      {:nhs_contract_price, :float}
    ]
end
