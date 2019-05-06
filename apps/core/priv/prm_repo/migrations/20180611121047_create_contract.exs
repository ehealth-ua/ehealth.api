defmodule Core.PRMRepo.Migrations.CreateContract do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:contracts, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:start_date, :date, null: false)
      add(:end_date, :date, null: false)
      add(:status, :string, null: false)
      add(:contractor_legal_entity_id, :uuid, null: false)
      add(:contractor_owner_id, :uuid, null: false)
      add(:contractor_base, :string, null: false)
      add(:contractor_payment_details, :map, null: false)
      add(:contractor_rmsp_amount, :integer, null: false)
      add(:external_contractor_flag, :boolean)
      add(:external_contractors, {:array, :map})
      add(:nhs_signer_id, :uuid, null: false)
      add(:nhs_signer_base, :string, null: false)
      add(:nhs_legal_entity_id, :uuid, null: false)
      add(:nhs_payment_method, :string, null: false)
      add(:is_active, :boolean, null: false)
      add(:is_suspended, :boolean, null: false)
      add(:issue_city, :string, null: false)
      add(:nhs_contract_price, :float, null: false)
      add(:contract_number, :string, null: false)
      add(:contract_request_id, :uuid, null: false)
      add(:status_reason, :string)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
