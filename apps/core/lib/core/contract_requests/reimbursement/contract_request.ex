defmodule Core.ContractRequests.ReimbursementContractRequest do
  @moduledoc false

  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.MedicalPrograms.MedicalProgram
  alias Ecto.UUID

  @inheritance_name "REIMBURSEMENT"

  @fields_required ~w(
    type
    contractor_legal_entity_id
    contractor_owner_id
    contractor_base
    contractor_payment_details
    contractor_divisions
    start_date
    end_date
    id_form
    status
    inserted_by
    updated_by
  )a

  @fields_optional ~w(
    contract_number
    parent_contract_id
    previous_request_id
    medical_program_id
  )a

  use Core.ContractRequests.ContractRequest,
    inheritance_name: @inheritance_name,
    fields: [
      {:medical_program_id, UUID}
    ]

  def related_schemas, do: ~w(assignee contractor_legal_entity medical_program)a

  def related_schema(:assignee), do: Employee
  def related_schema(:contractor_legal_entity), do: LegalEntity
  def related_schema(:medical_program), do: MedicalProgram
  def related_schema(_), do: nil

  def changeset(%__MODULE__{} = contract_request, params) do
    contract_request
    |> cast(params, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end
