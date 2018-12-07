defmodule Core.FraudRepo.Migrations.CreateContractRequests do
  use Ecto.Migration

  def change do
    create table(:contract_requests, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:contractor_legal_entity_id, :uuid, null: false)
      add(:contractor_owner_id, :uuid, null: false)
      add(:contractor_base, :string, null: false)
      add(:contractor_payment_details, :map, null: false)
      add(:contractor_payment_details_mfo, :string)
      add(:contractor_payment_details_bank_name, :string)
      add(:contractor_payment_details_payer_account, :string)
      add(:contractor_rmsp_amount, :integer)
      add(:external_contractor_flag, :boolean)
      add(:external_contractors, :map)
      add(:contractor_employee_divisions, :map)
      add(:start_date, :date, null: false)
      add(:end_date, :date, null: false)
      add(:nhs_legal_entity_id, :uuid)
      add(:nhs_signer_id, :uuid)
      add(:nhs_signer_base, :string)
      add(:contractor_signed, :boolean)
      add(:issue_city, :string)
      add(:status, :string, null: false)
      add(:status_reason, :text)
      add(:nhs_contract_price, :float)
      add(:nhs_payment_method, :string)
      add(:contract_number, :string)
      add(:contract_id, :uuid)
      add(:id_form, :string, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)
      add(:contractor_divisions, {:array, :uuid}, null: false)
      add(:nhs_signed_date, :date)
      add(:parent_contract_id, :uuid)
      add(:misc, :text)
      add(:assignee_id, :uuid)
      add(:previous_request_id, references(:contract_requests, type: :uuid))

      timestamps()
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_contract_requests_contractor_payment_details()
    RETURNS trigger AS
    $BODY$
    BEGIN
      NEW.contractor_payment_details_mfo = NEW.contractor_payment_details->>'MFO';
      NEW.contractor_payment_details_bank_name = NEW.contractor_payment_details->>'bank_name';
      NEW.contractor_payment_details_payer_account = NEW.contractor_payment_details->>'payer_account';
      NEW.contractor_payment_details = null;

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_contract_request_insert
    BEFORE INSERT
    ON contract_requests
    FOR EACH ROW
    EXECUTE PROCEDURE set_contract_requests_contractor_payment_details();
    """)

    execute("""
    CREATE TRIGGER on_contract_request_update
    BEFORE UPDATE
    ON contract_requests
    FOR EACH ROW
    WHEN (OLD.contractor_payment_details IS DISTINCT FROM NEW.contractor_payment_details)
    EXECUTE PROCEDURE set_contract_requests_contractor_payment_details();
    """)

    execute("ALTER table contract_requests ENABLE REPLICA TRIGGER on_contract_request_insert;")
    execute("ALTER table contract_requests ENABLE REPLICA TRIGGER on_contract_request_update;")
  end
end
