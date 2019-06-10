defmodule Core.PRMRepo.Migrations.RenameServiceGroupsParentIdToParentGroupId do
  use Ecto.Migration

  def change do
    rename table(:service_groups), :parent_id, to: :parent_group_id
  end
end
