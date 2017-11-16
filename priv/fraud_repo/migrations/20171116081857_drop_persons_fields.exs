defmodule EHealth.FraudRepo.Migrations.DropPersonsFields do
  use Ecto.Migration

  def change do
    execute("DROP TRIGGER IF EXISTS on_person_insert ON persons;")
    execute("DROP TRIGGER IF EXISTS on_person_update ON persons;")

    alter table(:persons) do
      remove :first_name
      remove :second_name
      remove :last_name
      remove :birth_settlement
      remove :tax_id
      remove :national_id
      remove :secret
      remove :passport_number
      remove :national_id_number
      remove :birth_certificate_number
      remove :temporary_certificate_number
      remove :emergency_contact
      remove :ec_first_name
      remove :ec_last_name
      remove :ec_second_name
      remove :ec_mobile_phone
      remove :ec_land_line_phone
      remove :confidant_person
      remove :cp1_first_name
      remove :cp1_last_name
      remove :cp1_second_name
      remove :cp1_birth_date
      remove :cp1_birth_country
      remove :cp1_birth_settlement
      remove :cp1_gender
      remove :cp1_tax_id
      remove :cp1_secret
      remove :cp1_passport_number
      remove :cp1_national_id_number
      remove :cp1_birth_certificate_number
      remove :cp1_temporary_certificate_number
      remove :cp1_doc_relationship_document_number
      remove :cp1_doc_relationship_court_decision_number
      remove :cp1_doc_relationship_birth_cert_number
      remove :cp1_doc_relationship_confidant_cert_number
      remove :cp1_mobile_phone
      remove :cp1_land_line_phone
      remove :cp2_first_name
      remove :cp2_last_name
      remove :cp2_second_name
      remove :cp2_birth_date
      remove :cp2_birth_country
      remove :cp2_birth_settlement
      remove :cp2_gender
      remove :cp2_tax_id
      remove :cp2_secret
      remove :cp2_passport_number
      remove :cp2_national_id_number
      remove :cp2_birth_certificate_number
      remove :cp2_temporary_certificate_number
      remove :cp2_doc_relationship_document_number
      remove :cp2_doc_relationship_court_decision_number
      remove :cp2_doc_relationship_birth_cert_number
      remove :cp2_doc_relationship_confidant_cert_number
      remove :cp2_mobile_phone
      remove :cp2_land_line_phone
      remove :addresses
      remove :registration_country
      remove :registration_area
      remove :registration_region
      remove :registration_settlement
      remove :registration_settlement_type
      remove :registration_settlement_id
      remove :registration_street_type
      remove :registration_street
      remove :registration_building
      remove :registration_zip
      remove :residence_country
      remove :residence_area
      remove :residence_region
      remove :residence_settlement
      remove :residence_settlement_type
      remove :residence_settlement_id
      remove :residence_street_type
      remove :residence_street
      remove :residence_building
      remove :residence_zip
      remove :documents
    end

    execute """
    CREATE OR REPLACE FUNCTION set_person_fields()
    RETURNS trigger AS
    $BODY$
    DECLARE
      phone jsonb;
      authentication_method jsonb = NEW.authentication_methods->0;
    BEGIN
      FOR phone IN SELECT * FROM jsonb_array_elements(NEW.phones) LOOP
        IF phone->>'type' = 'MOBILE' THEN
          NEW.mobile_phone = phone->>'number';
        END IF;

        IF phone->>'type' = 'LAND_LINE' THEN
          NEW.land_line_phone = phone->>'number';
        END IF;
      END LOOP;

      NEW.auth_method = authentication_method->>'type';
      IF authentication_method->>'type' = 'OTP' THEN
        NEW.auth_number = authentication_method->>'phone_number';
      END IF;

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER on_person_insert
    BEFORE INSERT
    ON persons
    FOR EACH ROW
    EXECUTE PROCEDURE set_person_fields();
    """

    execute """
    CREATE TRIGGER on_person_update
    BEFORE UPDATE
    ON persons
    FOR EACH ROW
    WHEN (
      OLD.phones IS DISTINCT FROM NEW.phones OR
      OLD.authentication_methods IS DISTINCT FROM NEW.authentication_methods
    )
    EXECUTE PROCEDURE set_person_fields();
    """

    execute("ALTER table persons ENABLE REPLICA TRIGGER on_person_insert;")
    execute("ALTER table persons ENABLE REPLICA TRIGGER on_person_update;")
  end
end
