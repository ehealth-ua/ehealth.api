defmodule EHealth.Repo.Migrations.CredentialsRecoveryRequests do
  use Ecto.Migration

  def change do
    create table(:credentials_recovery_requests, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, :uuid
      add :is_active, :boolean, default: true

      timestamps()
    end
  end
end
