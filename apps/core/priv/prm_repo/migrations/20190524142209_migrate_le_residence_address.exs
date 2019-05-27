defmodule Core.PRMRepo.Migrations.MigrateLeResidenceAddress do
  use Ecto.Migration

  def change do
    execute("""
      DO
      $$DECLARE r RECORD;
      BEGIN

        FOR r IN (WITH ll AS (
            SELECT
              le.id,
              jsonb_array_elements(le.addresses) address
            FROM legal_entities le)
        SELECT *
        FROM ll
        WHERE ll.address ->> 'type' = 'RESIDENCE')
        LOOP
          UPDATE legal_entities
          SET residence_address = r.address,
              updated_at = now()
          WHERE id = r.id;
        END LOOP;

      END$$;
    """)
  end
end
