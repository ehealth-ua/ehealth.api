defmodule Core.FraudRepo.Migrations.CreateIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:dosage, :map, null: false)
      add(:is_primary, :boolean, default: false, null: false)

      add(:numerator_unit, :string)
      add(:numerator_value, :numeric)
      add(:denumerator_unit, :string)
      add(:denumerator_value, :numeric)

      add(:parent_id, :uuid, null: false)
      add(:innm_child_id, :uuid, null: true)
      add(:medication_child_id, :uuid, null: true)

      timestamps(type: :utc_datetime_usec)
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_ingredient_dosage()
    RETURNS trigger AS
    $BODY$
    BEGIN
      NEW.numerator_unit = NEW.dosage->>'numerator_unit';
      NEW.numerator_value = NEW.dosage->>'numerator_value';
      NEW.denumerator_unit = NEW.dosage->>'denumerator_unit';
      NEW.denumerator_value = NEW.dosage->>'denumerator_value';

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_ingredient_insert
    BEFORE INSERT
    ON ingredients
    FOR EACH ROW
    EXECUTE PROCEDURE set_ingredient_dosage();
    """)

    execute("""
    CREATE TRIGGER on_ingredient_update
    BEFORE UPDATE
    ON ingredients
    FOR EACH ROW
    WHEN (OLD.dosage IS DISTINCT FROM NEW.dosage)
    EXECUTE PROCEDURE set_ingredient_dosage();
    """)

    execute("ALTER table ingredients ENABLE REPLICA TRIGGER on_ingredient_insert;")
    execute("ALTER table ingredients ENABLE REPLICA TRIGGER on_ingredient_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_ingredient_insert ON ingredients;")
    execute("DROP TRIGGER IF EXISTS on_ingredient_update ON ingredients;")
    execute("DROP FUNCTION IF EXISTS set_ingredient_dosage();")

    drop(table(:ingredients))
  end
end
