defmodule Core.PRMRepo.Migrations.CreateServicesCodeUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:services, :code, where: "is_active = true")
  end
end
