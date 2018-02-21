defmodule EHealth.FraudRepo.Migrations.RefactorEmployeeSpecialty do
  @moduledoc false

  use Ecto.Migration
  import Ecto.Changeset
  alias EHealth.Employees.Employee
  alias EHealth.Employees
  alias EHealth.Repo

  def up do
    alter table(:employees) do
      add(:speciality, :jsonb)
      remove(:educations)
      remove(:educations_qty)
      remove(:qualifications)
      remove(:qualifications_qty)
      remove(:specialities)
      remove(:specialities_qty)
      modify(:speciality_officio, :text)
      remove(:science_degree)
    end

    execute("DROP TRIGGER IF EXISTS on_employee_insert ON employees;")
    execute("DROP TRIGGER IF EXISTS on_employee_update ON employees;")
    execute("DROP FUNCTION IF EXISTS set_employee_additional_info();")

    execute("""
    CREATE OR REPLACE FUNCTION set_employee_speciality_officio()
    RETURNS trigger AS
    $BODY$
    BEGIN
      IF NEW.speciality->>'speciality' IS NOT NULL THEN
        NEW.speciality_officio = NEW.speciality->>'speciality';
        NEW.speciality_officio_valid_to_date = NEW.speciality->'valid_to_date';
      ELSE
        NEW.speciality_officio = null;
        NEW.speciality_officio_valid_to_date = null;
      END IF;

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_employee_insert
    BEFORE INSERT
    ON employees
    FOR EACH ROW
    EXECUTE PROCEDURE set_employee_speciality_officio();
    """)

    execute("""
    CREATE TRIGGER on_employee_update
    BEFORE UPDATE
    ON employees
    FOR EACH ROW
    WHEN (OLD.speciality IS DISTINCT FROM NEW.speciality)
    EXECUTE PROCEDURE set_employee_speciality_officio();
    """)

    execute("ALTER table employees ENABLE REPLICA TRIGGER on_employee_insert;")
    execute("ALTER table employees ENABLE REPLICA TRIGGER on_employee_update;")
  end
end
