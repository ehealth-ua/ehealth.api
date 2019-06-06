defmodule Core.PRMRepo.Migrations.ChangeServiceInclusionsPkey do
  use Ecto.Migration

  def after_begin do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")
  end

  def change do
    alter table(:service_inclusions) do
      add(:id, :uuid, default: fragment("uuid_generate_v4()"))
    end

    execute(
      "ALTER TABLE service_inclusions DROP CONSTRAINT service_inclusions_pkey",
      "ALTER TABLE service_inclusions ADD PRIMARY KEY (service_group_id, service_id)"
    );

    create unique_index(:service_inclusions, [:service_group_id, :service_id], where: "is_active = true")

    execute(
      "ALTER TABLE service_inclusions ADD PRIMARY KEY (id)",
      "ALTER TABLE service_inclusions DROP CONSTRAINT service_inclusions_pkey"
    )

    execute(
      "ALTER TABLE service_inclusions ALTER COLUMN id DROP DEFAULT",
      "ALTER TABLE service_inclusions ALTER COLUMN id SET DEFAULT uuid_generate_v4()"
    )
  end
end
