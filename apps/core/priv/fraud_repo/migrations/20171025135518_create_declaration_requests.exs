defmodule Core.FraudRepo.Migrations.CreateDeclarationRequests do
  use Ecto.Migration

  def up do
    create table(:declaration_requests, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:declaration_id, :uuid)

      add(:authentication_method_current, :jsonb, null: false)
      add(:auth_method, :string)
      add(:auth_number, :string)

      add(:status, :string, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps()
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_declaration_request_auth()
    RETURNS trigger AS
    $BODY$
    DECLARE
      type text = NEW.authentication_method_current->>'type';
    BEGIN
      NEW.auth_method = type;
      IF type = 'OTP' THEN
        NEW.auth_number = NEW.authentication_method_current->>'number';
      END IF;

      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER on_declaration_request_insert
    BEFORE INSERT
    ON declaration_requests
    FOR EACH ROW
    EXECUTE PROCEDURE set_declaration_request_auth();
    """)

    execute("""
    CREATE TRIGGER on_declaration_request_update
    BEFORE UPDATE
    ON declaration_requests
    FOR EACH ROW
    WHEN (OLD.authentication_method_current IS DISTINCT FROM NEW.authentication_method_current)
    EXECUTE PROCEDURE set_declaration_request_auth();
    """)

    execute("ALTER table declaration_requests ENABLE REPLICA TRIGGER on_declaration_request_insert;")
    execute("ALTER table declaration_requests ENABLE REPLICA TRIGGER on_declaration_request_update;")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_declaration_request_insert ON declaration_requests;")
    execute("DROP TRIGGER IF EXISTS on_declaration_request_update ON declaration_requests;")
    execute("DROP FUNCTION IF EXISTS set_declaration_request_auth();")

    drop(table(:declaration_requests))
  end
end
