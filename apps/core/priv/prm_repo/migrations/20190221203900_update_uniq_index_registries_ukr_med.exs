defmodule Core.PRMRepo.Migrations.CreatePRM.Registries.UkrMedRegistryIndexes do
  use Ecto.Migration

  def change do
    drop_if_exists(unique_index(:ukr_med_registries, [:edrpou]))
    create_if_not_exists(unique_index(:ukr_med_registries, [:edrpou, :type]))
  end
end
