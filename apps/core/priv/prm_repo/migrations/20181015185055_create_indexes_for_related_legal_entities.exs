defmodule Core.PRMRepo.Migrations.CreateIndexesForRelatedLegalEntities do
  use Ecto.Migration

  def change do
    create(unique_index(:related_legal_entities, [:merged_to_id, :merged_from_id, :is_active], name: :merged_ids_index))
  end
end
