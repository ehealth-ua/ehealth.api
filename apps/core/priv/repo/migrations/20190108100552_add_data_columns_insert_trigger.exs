defmodule Core.Repo.Migrations.AddDataColumnsInsertTrigger do
  use Ecto.Migration

  def change do
    execute("""
    CREATE OR REPLACE FUNCTION set_declaration_request_data()
    RETURNS trigger AS
    $BODY$
    BEGIN
      NEW.data_legal_entity_id = cast(NEW.data -> 'legal_entity' ->> 'id' as uuid);
      NEW.data_employee_id = cast(NEW.data -> 'employee' ->> 'id' as uuid);
      NEW.data_start_date_year = cast(date_part('year', to_timestamp(NEW.data ->> 'start_date', 'YYYY-MM-DD') AT TIME ZONE 'UTC') as numeric);
      NEW.data_person_tax_id = NEW.data -> 'person' ->> 'tax_id';
      NEW.data_person_first_name = NEW.data -> 'person' ->> 'first_name';
      NEW.data_person_last_name = NEW.data -> 'person' ->> 'last_name';
      NEW.data_person_birth_date = cast(NEW.data -> 'person' ->> 'birth_date' as date);

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_declaration_request_insert
    BEFORE INSERT
    ON declaration_requests
    FOR EACH ROW
    EXECUTE PROCEDURE set_declaration_request_data();
    """)
  end
end
