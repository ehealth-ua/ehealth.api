defmodule Core.PRMRepo.Migrations.CreatePRM.Registries.UkrMedRegistry do
  use Ecto.Migration

  def change do
    drop(unique_index(:ukr_med_registries, [:edrpou]))
    create(unique_index(:ukr_med_registries, [:edrpou, :type]))
  end
end
