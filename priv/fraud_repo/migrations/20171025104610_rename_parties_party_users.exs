defmodule EHealth.FraudRepo.Migrations.RenamePartiesPartyUsers do
  use Ecto.Migration

  def change do
    rename table(:parties_party_users), to: table(:party_users)
  end
end
