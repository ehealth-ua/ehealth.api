defmodule Core.FraudRepo.Migrations.CreateMedication do
  use Ecto.Migration

  def change do
    create table(:medications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:type, :string, null: false)

      add(:manufacturer, :map)
      add(:manufacturer_name, :string)
      add(:manufacturer_country, :string)

      add(:code_atc, :string)
      add(:is_active, :boolean, default: false, null: false)
      add(:form, :string)

      add(:container, :map)
      add(:numerator_unit, :string)
      add(:numerator_value, :numeric)
      add(:denumerator_unit, :string)
      add(:denumerator_value, :numeric)

      add(:package_qty, :integer)
      add(:package_min_qty, :integer)
      add(:certificate, :string)
      add(:certificate_expired_at, :date)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps(type: :utc_datetime)
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_medication_manufacturer_and_container()
    RETURNS trigger AS
    $BODY$
    BEGIN
      NEW.manufacturer_name = NEW.manufacturer->>'name';
      NEW.manufacturer_country = NEW.manufacturer->>'country';

      NEW.numerator_unit = NEW.container->>'numerator_unit';
      NEW.numerator_value = NEW.container->>'numerator_value';
      NEW.denumerator_unit = NEW.container->>'denumerator_unit';
      NEW.denumerator_value = NEW.container->>'denumerator_value';

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_medication_insert
    BEFORE INSERT
    ON medications
    FOR EACH ROW
    EXECUTE PROCEDURE set_medication_manufacturer_and_container();
    """)

    execute("""
    CREATE TRIGGER on_medication_update
    BEFORE UPDATE
    ON medications
    FOR EACH ROW
    WHEN (OLD.manufacturer IS DISTINCT FROM NEW.manufacturer OR OLD.container IS DISTINCT FROM NEW.container)
    EXECUTE PROCEDURE set_medication_manufacturer_and_container();
    """)

    execute("ALTER table medications ENABLE REPLICA TRIGGER on_medication_insert;")
    execute("ALTER table medications ENABLE REPLICA TRIGGER on_medication_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_medication_insert ON medications;")
    execute("DROP TRIGGER IF EXISTS on_medication_update ON medications;")
    execute("DROP FUNCTION IF EXISTS set_medication_manufacturer_and_container();")

    drop(table(:medications))
  end
end
