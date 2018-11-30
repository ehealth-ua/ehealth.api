defmodule Core.Contracts.ReimbursementContract do
  @moduledoc false

  import Ecto.Changeset

  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.MedicalPrograms.MedicalProgram
  alias Ecto.UUID

  @inheritance_name ReimbursementContractRequest.type()

  @fields_required ~w(
    id
    start_date
    end_date
    status
    contractor_legal_entity_id
    contractor_owner_id
    contractor_base
    contractor_payment_details
    nhs_legal_entity_id
    nhs_signer_id
    nhs_payment_method
    nhs_signer_base
    issue_city
    contract_number
    contract_request_id
    is_suspended
    is_active
    inserted_by
    updated_by
    id_form
    nhs_signed_date
    medical_program_id
  )a

  @fields_optional ~w(
    parent_contract_id
    status_reason
  )a

  use Core.Contracts.Contract,
    inheritance_name: @inheritance_name,
    belongs_to: [
      {:medical_program, MedicalProgram, type: UUID}
    ]

  def changeset(%__MODULE__{} = contract, attrs) do
    contract
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> cast_assoc(:contract_divisions)
    |> validate_required(@fields_required)
  end
end
