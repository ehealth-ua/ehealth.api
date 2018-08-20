defmodule Core.FraudRepo.Migrations.CreateProgramMedications do
  use Ecto.Migration

  def change do
    create table(:program_medications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:reimbursement, :map, null: false)
      add(:reimbursement_type, :string)
      add(:reimbursement_amount, :numeric)

      add(:is_active, :boolean, null: false)
      add(:medication_request_allowed, :boolean, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      add(:medication_id, :uuid, null: false)
      add(:medical_program_id, :uuid, null: false)

      timestamps()
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_program_medication_reimbursement()
    RETURNS trigger AS
    $BODY$
    BEGIN
      NEW.reimbursement_type = NEW.reimbursement->>'type';
      NEW.reimbursement_amount = NEW.reimbursement->>'reimbursement_amount';

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_program_medication_insert
    BEFORE INSERT
    ON program_medications
    FOR EACH ROW
    EXECUTE PROCEDURE set_program_medication_reimbursement();
    """)

    execute("""
    CREATE TRIGGER on_program_medication_update
    BEFORE UPDATE
    ON program_medications
    FOR EACH ROW
    WHEN (OLD.reimbursement IS DISTINCT FROM NEW.reimbursement)
    EXECUTE PROCEDURE set_program_medication_reimbursement();
    """)

    execute("ALTER table program_medications ENABLE REPLICA TRIGGER on_program_medication_insert;")
    execute("ALTER table program_medications ENABLE REPLICA TRIGGER on_program_medication_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_program_medication_insert ON program_medications;")
    execute("DROP TRIGGER IF EXISTS on_program_medication_update ON program_medications;")
    execute("DROP FUNCTION IF EXISTS set_program_medication_reimbursement();")

    drop(table(:program_medications))
  end
end
