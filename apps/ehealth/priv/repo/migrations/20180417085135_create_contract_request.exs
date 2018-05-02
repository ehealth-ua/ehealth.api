defmodule EHealth.Repo.Migrations.CreateContractRequest do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:contract_requests, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:contractor_legal_entity_id, :uuid, null: false)
      add(:contractor_owner_id, :uuid, null: false)
      add(:contractor_base, :string, null: false)
      add(:contractor_payment_details, :map, null: false)
      add(:contractor_rmsp_amount, :integer, null: false)
      add(:external_contractor_flag, :boolean)
      add(:external_contractors, {:array, :map})
      add(:contractor_employee_divisions, {:array, :map}, null: false)
      add(:start_date, :date, null: false)
      add(:end_date, :date, null: false)
      add(:nhs_legal_entity_id, :uuid)
      add(:nhs_signer_id, :uuid)
      add(:nhs_signer_base, :string)
      add(:nhs_signed, :boolean)
      add(:contractor_signed, :boolean)
      add(:issue_city, :string)
      add(:status, :string, null: false)
      add(:status_reason, :string)
      add(:nhs_contract_price, :float)
      add(:nhs_payment_method, :string)
      add(:contract_number, :string)
      add(:contract_id, :uuid)
      add(:printout_content, :string)
      add(:id_form, :string, null: false)
      add(:data, :map)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps()
    end
  end
end
