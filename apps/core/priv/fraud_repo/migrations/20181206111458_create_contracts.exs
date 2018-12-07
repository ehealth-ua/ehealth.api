defmodule Core.FraudRepo.Migrations.CreateContracts do
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
      add(:contractor_payment_details, :map)
      add(:contractor_payment_details_mfo, :string)
      add(:contractor_payment_details_bank_name, :string)
      add(:contractor_payment_details_payer_account, :string)
      add(:contractor_rmsp_amount, :integer)
      add(:external_contractor_flag, :boolean)
      add(:external_contractors, :map)
      add(:nhs_signer_id, :uuid, null: false)
      add(:nhs_signer_base, :string, null: false)
      add(:nhs_legal_entity_id, :uuid, null: false)
      add(:nhs_payment_method, :string, null: false)
      add(:is_active, :boolean, null: false)
      add(:is_suspended, :boolean, null: false)
      add(:issue_city, :string, null: false)
      add(:nhs_contract_price, :float)
      add(:contract_number, :string, null: false)
      add(:contract_request_id, :uuid, null: false)
      add(:status_reason, :text)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)
      add(:parent_contract_id, :uuid)
      add(:id_form, :string, null: false)
      add(:nhs_signed_date, :date, null: false)

      timestamps()
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_contracts_contractor_payment_details()
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
    CREATE TRIGGER on_contract_insert
    BEFORE INSERT
    ON contracts
    FOR EACH ROW
    EXECUTE PROCEDURE set_contracts_contractor_payment_details();
    """)

    execute("""
    CREATE TRIGGER on_contract_update
    BEFORE UPDATE
    ON contracts
    FOR EACH ROW
    WHEN (OLD.contractor_payment_details IS DISTINCT FROM NEW.contractor_payment_details)
    EXECUTE PROCEDURE set_contracts_contractor_payment_details();
    """)

    execute("ALTER table contracts ENABLE REPLICA TRIGGER on_contract_insert;")
    execute("ALTER table contracts ENABLE REPLICA TRIGGER on_contract_update;")
  end
end
