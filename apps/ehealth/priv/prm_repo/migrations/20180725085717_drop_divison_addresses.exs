defmodule EHealth.PRMRepo.Migrations.DropDivisonAddresses do
  use Ecto.Migration

  def change do
    alter table(:divisions) do
      remove :addresses
    end
  end
end
