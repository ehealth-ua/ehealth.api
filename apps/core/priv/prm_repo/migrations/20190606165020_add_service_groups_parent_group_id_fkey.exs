defmodule Core.PRMRepo.Migrations.AddServiceGroupsParentGroupIdFkey do
  use Ecto.Migration

  def change do
    alter table(:service_groups) do
      modify(:parent_group_id, references(:service_groups, type: :uuid), from: :uuid)
    end
  end
end
