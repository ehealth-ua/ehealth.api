defmodule Core.FraudRepo.Migrations.DropPartiesFields do
  use Ecto.Migration

  def change do
    execute("DROP TRIGGER IF EXISTS on_party_insert ON parties;")
    execute("DROP TRIGGER IF EXISTS on_party_update ON parties;")

    alter table(:parties) do
      remove(:first_name)
      remove(:second_name)
      remove(:last_name)
      remove(:passport_number)
      remove(:national_id_number)
      remove(:temporary_certificate_number)
      remove(:birth_certificate_number)
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_party_documents_phones()
    RETURNS trigger AS
    $BODY$
    DECLARE
      phone jsonb;
    BEGIN
      FOR phone IN SELECT * FROM jsonb_array_elements(NEW.phones) LOOP
        IF phone->>'type' = 'MOBILE' THEN
          NEW.mobile_phone = phone->>'number';
        END IF;

        IF phone->>'type' = 'LAND_LINE' THEN
          NEW.land_line_phone = phone->>'number';
        END IF;
      END LOOP;

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_party_insert
    BEFORE INSERT
    ON parties
    FOR EACH ROW
    EXECUTE PROCEDURE set_party_documents_phones();
    """)

    execute("""
    CREATE TRIGGER on_party_update
    BEFORE UPDATE
    ON parties
    FOR EACH ROW
    WHEN (OLD.phones IS DISTINCT FROM NEW.phones)
    EXECUTE PROCEDURE set_party_documents_phones();
    """)

    execute("ALTER table parties ENABLE REPLICA TRIGGER on_party_insert;")
    execute("ALTER table parties ENABLE REPLICA TRIGGER on_party_update;")
  end
end
