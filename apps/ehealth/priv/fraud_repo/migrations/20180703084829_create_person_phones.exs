defmodule EHealth.FraudRepo.Migrations.CreatePersonPhones do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:person_phones, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:person_id, :uuid)
      add(:number, :string)
      add(:type, :string)
      timestamps(type: :utc_datetime)
    end

    create(index(:person_phones, [:person_id]))

    execute("""
    CREATE OR REPLACE FUNCTION set_person_fields()
    RETURNS trigger AS
    $BODY$
    DECLARE
      authentication_method jsonb = NEW.authentication_methods->0;
    BEGIN
      NEW.auth_method = authentication_method->>'type';
      IF authentication_method->>'type' = 'OTP' THEN
        NEW.auth_number = authentication_method->>'phone_number';
      END IF;

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("DROP TRIGGER IF EXISTS on_person_insert ON persons;")
    execute("DROP TRIGGER IF EXISTS on_person_update ON persons;")

    execute("""
    CREATE TRIGGER on_person_insert
    BEFORE INSERT
    ON persons
    FOR EACH ROW
    EXECUTE PROCEDURE set_person_fields();
    """)

    execute("""
    CREATE TRIGGER on_person_update
    BEFORE UPDATE
    ON persons
    FOR EACH ROW
    WHEN (OLD.authentication_methods IS DISTINCT FROM NEW.authentication_methods)
    EXECUTE PROCEDURE set_person_fields();
    """)

    execute("ALTER table persons ENABLE REPLICA TRIGGER on_person_insert;")
    execute("ALTER table persons ENABLE REPLICA TRIGGER on_person_update;")

    alter table(:persons) do
      remove(:phones)
    end
  end
end
