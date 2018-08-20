defmodule Core.PRMRepo.Migrations.RenamePartyUsers do
  use Ecto.Migration

  def change do
    rename(table(:parties_party_users), to: table(:party_users))
  end
end
