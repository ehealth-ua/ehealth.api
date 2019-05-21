defmodule Core.Repo.Migrations.AddMrrDataColumnsInsertTrigger do
  use Ecto.Migration

  def change do
    execute("""
      CREATE OR REPLACE FUNCTION set_medication_request_request_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        NEW.data_person_id = cast(NEW.data ->> 'person_id' as uuid);
        NEW.data_employee_id = cast(NEW.data ->> 'employee_id' as uuid);
        NEW.data_intent = NEW.data ->> 'intent';

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
  end
end
