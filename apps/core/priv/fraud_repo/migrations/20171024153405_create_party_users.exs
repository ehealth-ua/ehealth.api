defmodule Core.FraudRepo.Migrations.CreatePartyUsers do
  use Ecto.Migration

  def change do
    create table(:party_users, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, :uuid, null: false)
      add(:party_id, :uuid)

      timestamps()
    end
  end
end
