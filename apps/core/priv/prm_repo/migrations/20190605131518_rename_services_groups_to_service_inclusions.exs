defmodule Core.PRMRepo.Migrations.RenameServicesGroupsToServiceInclusions do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE services_groups RENAME CONSTRAINT services_groups_pkey TO service_inclusions_pkey",
      "ALTER TABLE services_groups RENAME CONSTRAINT service_inclusions_pkey TO services_groups_pkey"
    )

    execute(
      "ALTER TABLE services_groups RENAME CONSTRAINT services_groups_service_group_id_fkey TO service_inclusions_service_group_id_fkey",
      "ALTER TABLE services_groups RENAME CONSTRAINT service_inclusions_service_group_id_fkey TO services_groups_service_group_id_fkey"
    )

    execute(
      "ALTER TABLE services_groups RENAME CONSTRAINT services_groups_service_id_fkey TO service_inclusions_service_id_fkey",
      "ALTER TABLE services_groups RENAME CONSTRAINT service_inclusions_service_id_fkey TO services_groups_service_id_fkey"
    )

    rename(table(:services_groups), to: table(:service_inclusions))
  end
end
