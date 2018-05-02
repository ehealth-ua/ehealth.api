defmodule EHealth.ContractRequests.ContractRequest do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @derive {Poison.Encoder, except: [:__meta__]}

  @primary_key {:id, :binary_id, autogenerate: true}

  @status_new "NEW"
  @status_declined "DECLINED"
  @status_approved "APPROVED"
  @status_signed "SIGNED"
  @status_terminated "TERMINATED"

  def status(:new), do: @status_new
  def status(:declined), do: @status_declined
  def status(:approved), do: @status_approved
  def status(:signed), do: @status_signed
  def status(:terminated), do: @status_terminated

  schema "contract_requests" do
    field(:contractor_legal_entity_id, UUID)
    field(:contractor_owner_id, UUID)
    field(:contractor_base, :string)
    field(:contractor_payment_details, :map)
    field(:contractor_rmsp_amount, :integer)
    field(:external_contractor_flag, :boolean, default: false)
    field(:external_contractors, {:array, :map})
    field(:contractor_employee_divisions, {:array, :map})
    field(:start_date, :date)
    field(:end_date, :date)
    field(:nhs_legal_entity_id, UUID)
    field(:nhs_signer_id, UUID)
    field(:nhs_signer_base, :string)
    field(:issue_city, :string)
    field(:status, :string)
    field(:status_reason, :string)
    field(:nhs_contract_price, :float)
    field(:nhs_payment_method, :string)
    field(:nhs_signed, :boolean)
    field(:contract_number, :string)
    field(:contract_id, UUID)
    field(:contractor_signed, :boolean)
    field(:printout_content, :string)
    field(:id_form, :string)
    field(:data, :map)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    timestamps()
  end
end
