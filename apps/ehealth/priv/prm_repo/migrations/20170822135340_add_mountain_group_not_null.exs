defmodule EHealth.PRMRepo.Migrations.AddMountainGroupNotNull do
  use Ecto.Migration

  def change do
    alter table(:divisions) do
      modify(:mountain_group, :boolean, null: false)
    end
  end
end
