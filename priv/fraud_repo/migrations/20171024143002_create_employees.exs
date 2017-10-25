defmodule EHealth.FraudRepo.Migrations.CreateEmployees do
  use Ecto.Migration

  def up do
    create table(:employees, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :position, :string, null: false
      add :status, :string, null: false
      add :employee_type, :string, null: false
      add :is_active, :boolean, default: false, null: false
      add :inserted_by, :uuid, null: false
      add :updated_by, :uuid, null: false
      add :start_date, :date, null: false
      add :end_date, :date
      add :legal_entity_id, :uuid
      add :division_id, :uuid
      add :party_id, :uuid
      add :status_reason, :string

      add :additional_info, :jsonb, null: false
      add :educations, :jsonb
      add :educations_qty, :integer, default: 0
      add :qualifications, :jsonb
      add :qualifications_qty, :integer, default: 0
      add :specialities, :jsonb
      add :specialities_qty, :integer, default: 0
      add :speciality_officio, :jsonb
      add :speciality_officio_valid_to_date, :date
      add :science_degree, :jsonb

      timestamps()
    end

    execute """
    CREATE OR REPLACE FUNCTION set_employee_additional_info()
    RETURNS trigger AS
    $BODY$
    DECLARE
      info jsonb = NEW.additional_info;
      specialty jsonb;
    BEGIN
      NEW.educations = info->>'educations';
      IF info->>'educations' IS NOT NULL THEN
        NEW.educations_qty = array_length(info->>'educations', 1);
      END IF;

      NEW.qualifications = info->>'qualifications';
      IF info->>'qualifications' IS NOT NULL THEN
        NEW.qualifications_qty = array_length(info->>'qualifications', 1);
      END IF;

      NEW.specialities = info->>'specialities';
      IF info->>'specialities' IS NOT NULL THEN
        NEW.specialities_qty = array_length(info->>'specialities', 1);

        FOR specialty IN SELECT * FROM jsonb_array_elements(info->>'specialities') LOOP
          IF specialty->>'speciality_officio' = TRUE THEN
            NEW.speciality_officio = specialty;
            NEW.speciality_officio_valid_to_date = specialty->>'valid_to_date'::date;
          END IF;
        END LOOP;
      END IF;

      NEW.science_degree = info->>'science_degree';

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER on_employee_insert
    AFTER INSERT
    ON employees
    FOR EACH ROW
    EXECUTE PROCEDURE set_employee_additional_info();
    """

    execute """
    CREATE TRIGGER on_employee_update
    AFTER UPDATE
    ON employees
    FOR EACH ROW
    WHEN (OLD.additional_info IS DISTINCT FROM NEW.additional_info)
    EXECUTE PROCEDURE set_employee_additional_info();
    """

    execute("ALTER table employees ENABLE REPLICA TRIGGER on_employee_insert;")
    execute("ALTER table employees ENABLE REPLICA TRIGGER on_employee_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_employee_insert ON employees;")
    execute("DROP TRIGGER IF EXISTS on_employee_update ON employees;")
    execute("DROP FUNCTION IF EXISTS set_employee_additional_info();")

    drop table(:employees)
  end
end
