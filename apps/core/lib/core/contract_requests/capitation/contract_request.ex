defmodule Core.ContractRequests.CapitationContractRequest do
  @moduledoc false

  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity

  @inheritance_name "CAPITATION"

  @fields_required ~w(
    type
    contractor_legal_entity_id
    contractor_owner_id
    contractor_base
    contractor_payment_details
    contractor_rmsp_amount
    contractor_divisions
    start_date
    end_date
    id_form
    status
    inserted_by
    updated_by
  )a

  @fields_optional ~w(
    contractor_employee_divisions
    external_contractor_flag
    external_contractors
    contract_number
    parent_contract_id
    previous_request_id
  )a

  use Core.ContractRequests.ContractRequest,
    inheritance_name: @inheritance_name,
    fields: [
      {:contractor_rmsp_amount, :integer},
      {:external_contractor_flag, :boolean, default: false},
      {:external_contractors, {:array, :map}},
      {:contractor_employee_divisions, {:array, :map}},
      {:nhs_contract_price, :float}
    ]

  def related_schemas, do: ~w(assignee contractor_legal_entity)a

  def related_schema(:assignee), do: Employee
  def related_schema(:contractor_legal_entity), do: LegalEntity
  def related_schema(_), do: nil

  def changeset(%__MODULE__{} = contract_request, params) do
    contract_request
    |> cast(params, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end
