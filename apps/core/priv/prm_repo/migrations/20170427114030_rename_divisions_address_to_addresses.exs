defmodule Core.PRMRepo.Migrations.RenameDivisionsAddressToAddresses do
  use Ecto.Migration

  def change do
    rename(table(:divisions), :address, to: :addresses)
  end
end
