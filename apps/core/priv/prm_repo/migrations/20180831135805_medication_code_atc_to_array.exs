defmodule Core.PRMRepo.Migrations.MedicationCodeAtcToArray do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    UPDATE medications
    SET code_atc = concat('["', trim(from code_atc), '"]')
    WHERE code_atc IS NOT NULL;
    """)

    execute("""
    ALTER TABLE medications
    ALTER COLUMN code_atc TYPE jsonb USING code_atc::jsonb;
    """)
  end
end
