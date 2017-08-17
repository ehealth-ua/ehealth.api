defmodule EHealth.PRMRepo.Migrations.AddPartyUsersIndex do
  use Ecto.Migration

  def change do
    create index(:party_users, [:party_id, :user_id], unique: true)
  end
end
