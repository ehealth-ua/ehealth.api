defmodule EHealth.FraudRepo.Migrations.CreateAuditLog do
  use Ecto.Migration

  def change do
    create table(:audit_log, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:actor_id, :string, null: false)
      add(:resource, :string, null: false)
      add(:resource_id, :string, null: false)
      add(:changeset, :jsonb, null: false)

      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
