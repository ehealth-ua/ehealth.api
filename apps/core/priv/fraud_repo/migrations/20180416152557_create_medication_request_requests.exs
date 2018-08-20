defmodule Core.FraudRepo.Migrations.CreateMedicationRequestRequests do
  use Ecto.Migration

  def change do
    create table(:medication_request_requests, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(:data, :map, null: false)
      add(:medication_qty, :integer)
      add(:ended_at, :string)
      add(:created_at, :string)
      add(:started_at, :string)
      add(:dispense_valid_to, :string)
      add(:dispense_valid_from, :string)
      add(:person_id, :uuid)
      add(:division_id, :uuid)
      add(:employee_id, :uuid)
      add(:medication_id, :uuid)
      add(:legal_entity_id, :uuid)
      add(:medical_program_id, :uuid)

      add(:request_number, :string, null: false)
      add(:status, :string, null: false)
      add(:verification_code, :string)
      add(:medication_request_id, :uuid, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)


      timestamps(type: :utc_datetime)
    end
    execute("""
    CREATE OR REPLACE FUNCTION set_medication_request_request_data()
    RETURNS trigger AS
    $BODY$
    BEGIN
      NEW.medication_qty = NEW.data->>'medication_qty';
      NEW.ended_at = NEW.data->>'ended_at';
      NEW.created_at = NEW.data->>'created_at';
      NEW.started_at = NEW.data->>'started_at';
      NEW.dispense_valid_to = NEW.data->>'dispense_valid_to';
      NEW.dispense_valid_from = NEW.data->>'dispense_valid_from';
      NEW.person_id = NEW.data->>'person_id';
      NEW.division_id = NEW.data->>'division_id';
      NEW.employee_id = NEW.data->>'employee_id';
      NEW.medication_id = NEW.data->>'medication_id';
      NEW.legal_entity_id = NEW.data->>'legal_entity_id';
      NEW.medical_program_id = NEW.data->>'medical_program_id';

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_medication_request_request_insert
    BEFORE INSERT
    ON medication_request_requests
    FOR EACH ROW
    EXECUTE PROCEDURE set_medication_request_request_data();
    """)

    execute("""
    CREATE TRIGGER on_medication_request_request_update
    BEFORE UPDATE
    ON medication_request_requests
    FOR EACH ROW
    WHEN (OLD.data IS DISTINCT FROM NEW.data)
    EXECUTE PROCEDURE set_medication_request_request_data();
    """)

    execute("ALTER table medication_request_requests ENABLE REPLICA TRIGGER on_medication_request_request_insert;")
    execute("ALTER table medication_request_requests ENABLE REPLICA TRIGGER on_medication_request_request_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_medication_request_request_insert ON medication_request_requests;")
    execute("DROP TRIGGER IF EXISTS on_medication_request_request_update ON medication_request_requests;")
    execute("DROP FUNCTION IF EXISTS set_medication_request_request_data();")

    drop(table(:medication_request_requests))
  end
end

