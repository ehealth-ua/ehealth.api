defmodule Core.PRMRepo.Migrations.AddIsActiveToServiceInclusions do
  use Ecto.Migration

  def change do
    alter table(:service_inclusions) do
      add(:is_active, :boolean, default: true, null: false)
    end
  end
end
