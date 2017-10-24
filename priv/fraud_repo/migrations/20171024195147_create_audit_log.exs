defmodule EHealth.FraudRepo.Migrations.CreateAuditLog do
  use Ecto.Migration

  def up do
    create table(:audit_log, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :actor_id, :string, null: false
      add :resource, :string, null: false
      add :resource_id, :string, null: false
      add :changeset, :string, null: false

      timestamps([type: :utc_datetime, updated_at: false])
    end

    execute """
    CREATE OR REPLACE FUNCTION set_audit_log_changeset()
    RETURNS trigger AS
    $BODY$
    BEGIN
      NEW.changeset = NEW.changeset::text;
      RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER on_audit_log_insert
    AFTER INSERT
    ON audit_log
    FOR EACH ROW
    EXECUTE PROCEDURE set_audit_log_changeset();
    """
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_audit_log_insert ON audit_log;")
    execute("DROP FUNCTION IF EXISTS set_audit_log_changeset();")

    drop table(:audit_log)
  end
end
