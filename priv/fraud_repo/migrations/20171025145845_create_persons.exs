defmodule EHealth.FraudRepo.Migrations.CreatePersons do
  use Ecto.Migration

  def up do
    create table(:persons, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :second_name, :string
      add :birth_date, :date, null: false
      add :birth_country, :string
      add :birth_settlement, :string, null: false
      add :gender, :string, null: false
      add :email, :string
      add :tax_id, :string
      add :national_id, :string
      add :death_date, :date, null: true
      add :is_active, :boolean, default: true
      add :secret, :string, null: false
      add :status, :string
      add :patient_signed, :boolean, null: false
      add :process_disclosure_data_consent, :boolean, null: false

      add :documents, :map
      add :passport_number, :string
      add :national_id_number, :string
      add :birth_certificate_number, :string
      add :temporary_certificate_number, :string

      add :addresses, :map
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

      add :phones, :map
      add :mobile_phone, :string
      add :land_line_phone, :string

      add :emergency_contact, :map
      add :ec_first_name, :string
      add :ec_last_name, :string
      add :ec_second_name, :string
      add :ec_mobile_phone, :string
      add :ec_land_line_phone, :string

      add :confidant_person, :map

      add :cp1_first_name, :string
      add :cp1_last_name, :string
      add :cp1_second_name, :string
      add :cp1_birth_date, :string
      add :cp1_birth_country, :string
      add :cp1_birth_settlement, :string
      add :cp1_gender, :string
      add :cp1_tax_id, :string
      add :cp1_secret, :string
      add :cp1_passport_number, :string
      add :cp1_national_id_number, :string
      add :cp1_birth_certificate_number, :string
      add :cp1_temporary_certificate_number, :string
      add :cp1_doc_relationship_document_number, :string
      add :cp1_doc_relationship_court_decision_number, :string
      add :cp1_doc_relationship_birth_cert_number, :string
      add :cp1_doc_relationship_confidant_cert_number, :string
      add :cp1_mobile_phone, :string
      add :cp1_land_line_phone, :string

      add :cp2_first_name, :string
      add :cp2_last_name, :string
      add :cp2_second_name, :string
      add :cp2_birth_date, :string
      add :cp2_birth_country, :string
      add :cp2_birth_settlement, :string
      add :cp2_gender, :string
      add :cp2_tax_id, :string
      add :cp2_secret, :string
      add :cp2_passport_number, :string
      add :cp2_national_id_number, :string
      add :cp2_birth_certificate_number, :string
      add :cp2_temporary_certificate_number, :string
      add :cp2_doc_relationship_document_number, :string
      add :cp2_doc_relationship_court_decision_number, :string
      add :cp2_doc_relationship_birth_cert_number, :string
      add :cp2_doc_relationship_confidant_cert_number, :string
      add :cp2_mobile_phone, :string
      add :cp2_land_line_phone, :string

      add :authentication_methods, :map
      add :auth_method, :string
      add :auth_number, :string

      add :inserted_by, :string, null: false
      add :updated_by, :string, null: false

      timestamps(type: :utc_datetime)
    end

    execute """
    CREATE OR REPLACE FUNCTION set_person_fields()
    RETURNS trigger AS
    $BODY$
    DECLARE
      document jsonb;
      address jsonb;
      phone jsonb;
      confidant_person jsonb;
      authentication_method jsonb = NEW.authentication_methods->0;
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

      NEW.ec_first_name = NEW.emergency_contact->>'first_name';
      NEW.ec_last_name = NEW.emergency_contact->>'last_name';
      NEW.ec_second_name = NEW.emergency_contact->>'second_name';

      FOR phone in SELECT * FROM jsonb_array_elements(NEW.emergency_contact->'phones') LOOP
        IF phone->>'type' = 'MOBILE' THEN
          NEW.ec_mobile_phone = phone->>'number';
        END IF;

        IF phone->>'type' = 'LAND_LINE' THEN
          NEW.ec_land_line_phone = phone->>'number';
        END IF;
      END LOOP;

      FOR confidant_person in SELECT * FROM jsonb_array_elements(NEW.confidant_person) LOOP
        IF confidant_person->>'relation_type' = 'PRIMARY' THEN
          NEW.cp1_first_name = confidant_person->>'first_name';
          NEW.cp1_last_name = confidant_person->>'last_name';
          NEW.cp1_second_name = confidant_person->>'second_name';
          NEW.cp1_birth_date = confidant_person->>'birth_date';
          NEW.cp1_birth_country = confidant_person->>'birth_country';
          NEW.cp1_birth_settlement = confidant_person->>'birth_settlement';
          NEW.cp1_gender = confidant_person->>'gender';
          NEW.cp1_tax_id = confidant_person->>'tax_id';
          NEW.cp1_secret = confidant_person->>'secret';

          FOR document in SELECT * FROM jsonb_array_elements(confidant_person->'documents') LOOP
            IF document->>'type' = 'PASSPORT' THEN
              NEW.cp1_passport_number = document->>'number';
            END IF;

            IF document->>'type' = 'NATIONAL_ID' THEN
              NEW.cp1_national_id_number = document->>'number';
            END IF;

            IF document->>'type' = 'BIRTH_CERTIFICATE' THEN
              NEW.cp1_birth_certificate_number = document->>'number';
            END IF;

            IF document->>'type' = 'TEMPORARY_CERTIFICATE' THEN
              NEW.cp1_temporary_certificate_number = document->>'number';
            END IF;
          END LOOP;

          FOR document in SELECT * FROM jsonb_array_elements(confidant_person->'documents_relationship') LOOP
            IF document->>'type' = 'DOCUMENT' THEN
              NEW.cp1_doc_relationship_document_number = document->>'number';
            END IF;

            IF document->>'type' = 'COURT_DECISION' THEN
              NEW.cp1_doc_relationship_court_decision_number = document->>'number';
            END IF;

            IF document->>'type' = 'BIRTH_CERTIFICATE' THEN
              NEW.cp1_doc_relationship_birth_cert_number = document->>'number';
            END IF;

            IF document->>'type' = 'CONFIDANT_CERTIFICATE' THEN
              NEW.cp1_doc_relationship_confidant_cert_number = document->>'number';
            END IF;
          END LOOP;

          FOR phone in SELECT * FROM jsonb_array_elements(confidant_person->'phones') LOOP
            IF phone->>'type' = 'MOBILE' THEN
              NEW.cp1_mobile_phone = phone->>'number';
            END IF;

            IF phone->>'type' = 'LAND_LINE' THEN
              NEW.cp1_land_line_phone = phone->>'number';
            END IF;
          END LOOP;
        END IF;

        IF confidant_person->>'relation_type' = 'SECONDARY' THEN
          NEW.cp2_first_name = confidant_person->>'first_name';
          NEW.cp2_last_name = confidant_person->>'last_name';
          NEW.cp2_second_name = confidant_person->>'second_name';
          NEW.cp2_birth_date = confidant_person->>'birth_date';
          NEW.cp2_birth_country = confidant_person->>'birth_country';
          NEW.cp2_birth_settlement = confidant_person->>'birth_settlement';
          NEW.cp2_gender = confidant_person->>'gender';
          NEW.cp2_tax_id = confidant_person->>'tax_id';
          NEW.cp2_secret = confidant_person->>'secret';

          FOR document in SELECT * FROM jsonb_array_elements(confidant_person->'documents') LOOP
            IF document->>'type' = 'PASSPORT' THEN
              NEW.cp2_passport_number = document->>'number';
            END IF;

            IF document->>'type' = 'NATIONAL_ID' THEN
              NEW.cp2_national_id_number = document->>'number';
            END IF;

            IF document->>'type' = 'BIRTH_CERTIFICATE' THEN
              NEW.cp2_birth_certificate_number = document->>'number';
            END IF;

            IF document->>'type' = 'TEMPORARY_CERTIFICATE' THEN
              NEW.cp2_temporary_certificate_number = document->>'number';
            END IF;
          END LOOP;

          FOR document in SELECT * FROM jsonb_array_elements(confidant_person->'documents_relationship') LOOP
            IF document->>'type' = 'DOCUMENT' THEN
              NEW.cp2_doc_relationship_document_number = document->>'number';
            END IF;

            IF document->>'type' = 'COURT_DECISION' THEN
              NEW.cp2_doc_relationship_court_decision_number = document->>'number';
            END IF;

            IF document->>'type' = 'BIRTH_CERTIFICATE' THEN
              NEW.cp2_doc_relationship_birth_cert_number = document->>'number';
            END IF;

            IF document->>'type' = 'CONFIDANT_CERTIFICATE' THEN
              NEW.cp2_doc_relationship_confidant_cert_number = document->>'number';
            END IF;
          END LOOP;

          FOR phone in SELECT * FROM jsonb_array_elements(confidant_person->'phones') LOOP
            IF phone->>'type' = 'MOBILE' THEN
              NEW.cp2_mobile_phone = phone->>'number';
            END IF;

            IF phone->>'type' = 'LAND_LINE' THEN
              NEW.cp2_land_line_phone = phone->>'number';
            END IF;
          END LOOP;
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
      OLD.addresses IS DISTINCT FROM NEW.addresses OR
      OLD.phones IS DISTINCT FROM NEW.phones OR
      OLD.emergency_contact IS DISTINCT FROM NEW.emergency_contact OR
      OLD.documents IS DISTINCT FROM NEW.documents OR
      OLD.confidant_person IS DISTINCT FROM NEW.confidant_person OR
      OLD.authentication_methods IS DISTINCT FROM NEW.authentication_methods
    )
    EXECUTE PROCEDURE set_person_fields();
    """

    execute("ALTER table persons ENABLE REPLICA TRIGGER on_person_insert;")
    execute("ALTER table persons ENABLE REPLICA TRIGGER on_person_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_person_insert ON persons;")
    execute("DROP TRIGGER IF EXISTS on_person_update ON persons;")
    execute("DROP FUNCTION IF EXISTS set_person_fields();")

    drop table(:persons)
  end
end
