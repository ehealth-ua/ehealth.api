defmodule EHealth.FraudRepo.Migrations.CreateParties do
  use Ecto.Migration

  def up do
    create table(:parties, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:first_name, :string, null: false)
      add(:second_name, :string)
      add(:last_name, :string, null: false)
      add(:birth_date, :date, null: false)
      add(:gender, :string, null: false)
      add(:tax_id, :string, null: false)

      add(:documents, :map)
      add(:passport_number, :string)
      add(:national_id_number, :string)
      add(:birth_certificate_number, :string)
      add(:temporary_certificate_number, :string)

      add(:phones, :map)
      add(:mobile_phone, :string)
      add(:land_line_phone, :string)

      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps()
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_party_documents_phones()
    RETURNS trigger AS
    $BODY$
    DECLARE
      document jsonb;
      phone jsonb;
    BEGIN
      FOR document in SELECT * FROM jsonb_array_elements(NEW.documents) LOOP
        IF document->>'type' = 'PASSPORT' THEN
          NEW.passport_number = document->>'number';
        END IF;

        IF document->>'type' = 'NATIONAL_ID' THEN
          NEW.national_id_number = document->>'number';
        END IF;

        IF document->>'type' = 'BIRTH_CERTIFICATE' THEN
          NEW.birth_certificate_number = document->>'number';
        END IF;

        IF document->>'type' = 'TEMPORARY_CERTIFICATE' THEN
          NEW.temporary_certificate_number = document->>'number';
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
    WHEN (OLD.documents IS DISTINCT FROM NEW.documents OR OLD.phones IS DISTINCT FROM NEW.phones)
    EXECUTE PROCEDURE set_party_documents_phones();
    """)

    execute("ALTER table parties ENABLE REPLICA TRIGGER on_party_insert;")
    execute("ALTER table parties ENABLE REPLICA TRIGGER on_party_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_party_insert ON parties;")
    execute("DROP TRIGGER IF EXISTS on_party_update ON parties;")
    execute("DROP FUNCTION IF EXISTS set_party_documents_phones();")

    drop(table(:parties))
  end
end
