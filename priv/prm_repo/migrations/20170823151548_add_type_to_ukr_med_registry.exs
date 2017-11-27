defmodule EHealth.PRMRepo.Migrations.AddTypeToUkrMedRegistry do
  use Ecto.Migration

  alias EHealth.LegalEntities.Registry

  def change do
    alter table(:ukr_med_registries) do
      add :type, :string, null: false, default: Registry.type(:msp)
    end
  end
end
