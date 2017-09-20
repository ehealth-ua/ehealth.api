defmodule EHealth.PRMRepo.Migrations.AddUniqueIndexToPartyUsers do
  use Ecto.Migration

  def change do
    create index(:party_users, [:user_id], unique: true)
  end
end
