defmodule EHealth.FraudRepo.Migrations.RemoveAuditLogTrigger do
  use Ecto.Migration

  def change do
    execute("DROP TRIGGER IF EXISTS on_audit_log_insert ON audit_log;")
    execute("DROP FUNCTION IF EXISTS set_audit_log_changeset();")

    execute(~s(ALTER TABLE "audit_log" ALTER COLUMN "changeset" TYPE jsonb USING changeset::jsonb))
  end
end
