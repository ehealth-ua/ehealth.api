defmodule EHealth.PRMRepo.Migrations.AddUniqueForLegalEntityEdrpou do
  use Ecto.Migration

  def change do
    create(unique_index(:legal_entities, [:edrpou]))
  end
end
