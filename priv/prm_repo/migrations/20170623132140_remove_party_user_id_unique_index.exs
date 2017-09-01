defmodule EHealth.PRMRepo.Migrations.RemovePartyUserIdUniqueIndex do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:party_users, [:user_id])
  end
end
