defmodule Core.PRMRepo.Migrations.RemoveServiceParentIdField do
  use Ecto.Migration

  def change do
    alter table(:services) do
      remove :parent_id
    end
  end
end
