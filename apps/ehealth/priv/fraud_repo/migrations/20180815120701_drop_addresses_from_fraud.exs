defmodule EHealth.FraudRepo.Migrations.DropAddressesFromFraud do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("DROP TRIGGER IF EXISTS on_division_insert ON divisions;")
    execute("DROP TRIGGER IF EXISTS on_division_update ON divisions;")
    execute("DROP FUNCTION IF EXISTS set_division_addresses_phones();")

    alter table(:divisions) do
      remove(:addresses)
      remove(:registration_country)
      remove(:registration_area)
      remove(:registration_region)
      remove(:registration_settlement)
      remove(:registration_settlement_type)
      remove(:registration_settlement_id)
      remove(:registration_street_type)
      remove(:registration_street)
      remove(:registration_building)
      remove(:registration_zip)

      remove(:residence_country)
      remove(:residence_area)
      remove(:residence_region)
      remove(:residence_settlement)
      remove(:residence_settlement_type)
      remove(:residence_settlement_id)
      remove(:residence_street_type)
      remove(:residence_street)
      remove(:residence_building)
      remove(:residence_zip)
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_division_phones()
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
    CREATE TRIGGER on_division_insert
    BEFORE INSERT
    ON divisions
    FOR EACH ROW
    EXECUTE PROCEDURE set_division_phones();
    """)

    execute("""
    CREATE TRIGGER on_division_update
    BEFORE UPDATE
    ON divisions
    FOR EACH ROW
    WHEN (OLD.phones IS DISTINCT FROM NEW.phones)
    EXECUTE PROCEDURE set_division_phones();
    """)

    execute("ALTER table divisions ENABLE REPLICA TRIGGER on_division_insert;")
    execute("ALTER table divisions ENABLE REPLICA TRIGGER on_division_update;")
  end
end
