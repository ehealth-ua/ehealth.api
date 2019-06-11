defmodule Core.PRMRepo.Migrations.CreateServiceGroupsCodeUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:service_groups, :code, where: "is_active = true")
  end
end
