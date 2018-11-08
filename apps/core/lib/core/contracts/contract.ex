defmodule Core.Contracts.Contract do
  @moduledoc false

  use Ecto.Schema

  alias Core.Contracts.ContractDivision
  alias Core.Contracts.ContractEmployee
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.RelatedLegalEntity
  alias Ecto.UUID

  @status_verified "VERIFIED"
  @status_terminated "TERMINATED"

  def status(:verified), do: @status_verified
  def status(:terminated), do: @status_terminated

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "contracts" do
    field(:start_date, :date)
    field(:end_date, :date)
    field(:status, :string)
    field(:status_reason, :string)
    field(:contractor_base, :string)
    field(:contractor_payment_details, :map)
    field(:contractor_rmsp_amount, :integer)
    field(:external_contractor_flag, :boolean)
    field(:external_contractors, {:array, :map})
    field(:nhs_payment_method, :string)
    field(:nhs_signer_base, :string)
    field(:issue_city, :string)
    field(:nhs_contract_price, :float)
    field(:contract_number, :string)
    field(:contract_request_id, UUID)
    field(:is_active, :boolean)
    field(:is_suspended, :boolean)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)
    field(:id_form, :string)
    field(:nhs_signed_date, :date)

    belongs_to(:contractor_legal_entity, LegalEntity, type: UUID)
    belongs_to(:contractor_owner, Employee, type: UUID)
    belongs_to(:nhs_legal_entity, LegalEntity, type: UUID)
    belongs_to(:nhs_signer, Employee, type: UUID)
    belongs_to(:parent_contract, __MODULE__, type: UUID)

    has_many(:contract_employees, ContractEmployee)
    has_many(:contract_divisions, ContractDivision)

    has_many(:divisions, through: [:contract_divisions, :division])
    has_many(:contract_employees_divisions, through: [:contract_employees, :division])

    has_one(:merged_from, RelatedLegalEntity, foreign_key: :merged_from_id, references: :contractor_legal_entity_id)
    has_many(:merged_to, RelatedLegalEntity, foreign_key: :merged_to_id, references: :contractor_legal_entity_id)

    timestamps()
  end
end
