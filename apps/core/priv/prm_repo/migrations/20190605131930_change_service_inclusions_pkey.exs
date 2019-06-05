defmodule Core.PRMRepo.Migrations.ChangeServiceInclusionsPkey do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE service_inclusions DROP CONSTRAINT service_inclusions_pkey",
      "ALTER TABLE service_inclusions ADD PRIMARY KEY (service_group_id, service_id)"
    );

    create unique_index(:service_inclusions, [:service_group_id, :service_id], where: "is_active = true")

    alter table(:service_inclusions) do
      add(:id, :uuid, primary_key: true)
    end
  end
end
