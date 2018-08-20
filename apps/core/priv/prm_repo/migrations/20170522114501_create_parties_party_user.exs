defmodule Core.PRMRepo.Migrations.CreatePRM.Parties.PartyUser do
  use Ecto.Migration

  def change do
    create table(:parties_party_users, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:user_id, :uuid, null: false)
      add(:party_id, references(:parties, type: :uuid, on_delete: :nothing))

      timestamps()
    end

    create(index(:parties_party_users, [:party_id]))
    create(unique_index(:parties_party_users, [:user_id]))
  end
end
