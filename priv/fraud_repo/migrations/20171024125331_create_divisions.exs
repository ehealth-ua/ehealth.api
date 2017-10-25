defmodule EHealth.FraudRepo.Migrations.CreateDivisions do
  use Ecto.Migration

  def up do
    create table(:divisions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :external_id, :string
      add :name, :string, null: false
      add :type, :string, null: false
      add :mountain_group, :string

      add :addresses, :map, null: false
      add :registration_country, :string
      add :registration_area, :string
      add :registration_region, :string
      add :registration_settlement, :string
      add :registration_settlement_type, :string
      add :registration_settlement_id, :string
      add :registration_street_type, :string
      add :registration_street, :string
      add :registration_building, :string
      add :registration_zip, :string

      add :residence_country, :string
      add :residence_area, :string
      add :residence_region, :string
      add :residence_settlement, :string
      add :residence_settlement_type, :string
      add :residence_settlement_id, :string
      add :residence_street_type, :string
      add :residence_street, :string
      add :residence_building, :string
      add :residence_zip, :string

      add :phones, :map, null: false
      add :mobile_phone, :string
      add :land_line_phone, :string

      add :email, :string
      add :legal_entity_id, :uuid
      add :status, :string, null: false
      add :is_active, :boolean, null: false
      add :location, :geometry

      timestamps()
    end

    execute """
    CREATE OR REPLACE FUNCTION set_division_addresses_phones()
    RETURNS trigger AS
    $BODY$
    DECLARE
      address jsonb;
      phone jsonb;
    BEGIN
      FOR address IN SELECT * FROM jsonb_array_elements(NEW.addresses) LOOP
        IF address->>'type' = 'REGISTRATION' THEN
          NEW.registration_country = address->>'country';
          NEW.registration_area = address->>'area';
          NEW.registration_region = address->>'region';
          NEW.registration_settlement = address->>'settlement';
          NEW.registration_settlement_type = address->>'settlement_type';
          NEW.registration_settlement_id = address->>'settlement_id';
          NEW.registration_street_type = address->>'street_type';
          NEW.registration_street = address->>'street';
          NEW.registration_building = CONCAT(address->>'building', ',', address->>'apartment');
          NEW.registration_zip = address->>'zip';
        END IF;

        IF address->>'type' = 'RESIDENCE' THEN
          NEW.residence_country = address->>'country';
          NEW.residence_area = address->>'area';
          NEW.residence_region = address->>'region';
          NEW.residence_settlement = address->>'settlement';
          NEW.residence_settlement_type = address->>'settlement_type';
          NEW.residence_settlement_id = address->>'settlement_id';
          NEW.residence_street_type = address->>'street_type';
          NEW.residence_street = address->>'street';
          NEW.residence_building = CONCAT(address->>'building', ',', address->>'apartment');
          NEW.residence_zip = address->>'zip';
        END IF;
      END LOOP;

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
    """

    execute """
    CREATE TRIGGER on_division_insert
    BEFORE INSERT
    ON divisions
    FOR EACH ROW
    EXECUTE PROCEDURE set_division_addresses_phones();
    """

    execute """
    CREATE TRIGGER on_division_update
    BEFORE UPDATE
    ON divisions
    FOR EACH ROW
    WHEN (OLD.addresses IS DISTINCT FROM NEW.addresses OR OLD.phones IS DISTINCT FROM NEW.phones)
    EXECUTE PROCEDURE set_division_addresses_phones();
    """

    execute("ALTER table divisions ENABLE REPLICA TRIGGER on_division_insert;")
    execute("ALTER table divisions ENABLE REPLICA TRIGGER on_division_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_division_insert ON divisions;")
    execute("DROP TRIGGER IF EXISTS on_division_update ON divisions;")
    execute("DROP FUNCTION IF EXISTS set_division_addresses_phones();")

    drop table(:divisions)
  end
end
