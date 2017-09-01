defmodule EHealth.PRMRepo.Migrations.RenamePartyUsersIndexes do
  use Ecto.Migration

  def change do
    drop_if_exists index(:parties_party_users, [:user_id])
    drop_if_exists index(:parties_party_users, [:party_id])
    execute "ALTER TABLE party_users DROP CONSTRAINT parties_party_users_party_id_fkey"

    alter table(:party_users) do
      modify :party_id, references(:parties, type: :uuid, on_delete: :nothing)
    end

    create unique_index(:party_users, [:user_id])
    create index(:party_users, [:party_id])
  end
end
