defmodule Core.Contracts.Contract do
  @moduledoc false

  use Ecto.Schema

  alias Core.Contracts.ContractDivision
  alias Core.Contracts.ContractEmployee
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
    field(:contractor_legal_entity_id, UUID)
    field(:contractor_owner_id, UUID)
    field(:contractor_base, :string)
    field(:contractor_payment_details, :map)
    field(:contractor_rmsp_amount, :integer)
    field(:external_contractor_flag, :boolean)
    field(:external_contractors, {:array, :map})
    field(:nhs_legal_entity_id, UUID)
    field(:nhs_signer_id, UUID)
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
    field(:parent_contract_id, UUID)
    field(:id_form, :string)
    field(:nhs_signed_date, :date)

    has_many(:contract_employees, ContractEmployee)
    has_many(:contract_divisions, ContractDivision)

    timestamps()
  end
end
