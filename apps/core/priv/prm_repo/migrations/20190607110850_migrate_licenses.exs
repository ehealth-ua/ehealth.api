defmodule Core.PRMRepo.Migrations.MigrateLicenses do
  use Ecto.Migration

  def change do
    execute("""
      DO
      $$DECLARE r           RECORD;
                has_license BOOLEAN;
      BEGIN

          FOR r IN (
              WITH lll AS (
                  WITH ll AS (
                      WITH l AS (
                          SELECT
                              msp.legal_entity_id,
                              jsonb_array_elements(msp.licenses) AS license
                          FROM medical_service_providers msp)
                      SELECT
                          l.legal_entity_id,
                          count(1)
                      FROM l
                      GROUP BY l.legal_entity_id
                      HAVING count(1) = 1)
                  SELECT
                      msp.legal_entity_id,
                      le.type,
                      msp.licenses -> 0 AS license
                  FROM ll, medical_service_providers msp, legal_entities le
                  WHERE ll.legal_entity_id = msp.legal_entity_id
                        AND le.id = ll.legal_entity_id
                        AND le.license_id IS NULL )
              SELECT
                  lll.legal_entity_id,
                  lll.license,
                  uuid_generate_v4()                     AS license_id,
                  CASE WHEN lll.type = 'MSP_PHARMACY'
                      THEN 'MSP'
                  ELSE lll.type
                  END                                    AS license_type,
                  lll.license ->> 'license_number'       AS license_number,
                  lll.license ->> 'type'                 AS type,
                  lll.license ->> 'issued_by'            AS issued_by,
                  lll.license ->> 'issued_date'          AS issued_date,
                  lll.license ->> 'issuer_status'        AS issuer_status,
                  lll.license ->> 'expiry_date'          AS expiry_date,
                  lll.license ->> 'active_from_date'     AS active_from_date,
                  lll.license ->> 'what_licensed'        AS what_licensed,
                  lll.license ->> 'order_no'             AS order_no,
                  '4261eacf-8008-4e62-899f-de1e2f7065f0' AS inserted_by,
                  '4261eacf-8008-4e62-899f-de1e2f7065f0' AS updated_by,
                  now()                                  AS inserted_at,
                  now()                                  AS updated_at
              FROM lll
          )

          LOOP

              SELECT count(1)
              INTO has_license
              FROM legal_entities
              WHERE id = r.legal_entity_id
                    AND license_id IS NOT NULL;

              IF NOT has_license :: BOOLEAN
              THEN
                  EXECUTE 'INSERT INTO licenses (id, is_active, license_number, type, issued_by, issued_date, issuer_status, expiry_date, active_from_date, what_licensed, order_no, inserted_by, updated_by, inserted_at, updated_at) VALUES ($1, true, $2, $3, $4, $5::date, $6, $7::date, $8::date, $9, $10, $11::uuid, $12::uuid, $13, $14);'
                  USING r.license_id, r.license_number, r.license_type, r.issued_by, r.issued_date, r.issuer_status, r.expiry_date, r.active_from_date, r.what_licensed, r.order_no, r.inserted_by, r.updated_by, r.inserted_at, r.updated_at;

                  EXECUTE 'UPDATE legal_entities SET license_id = $1, updated_at = now() WHERE id = $2'
                  USING r.license_id, r.legal_entity_id;
              END IF;

          END LOOP;

      END$$;
    """)
  end
end
