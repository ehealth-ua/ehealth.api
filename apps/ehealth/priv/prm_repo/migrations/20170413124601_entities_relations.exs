defmodule EHealth.PRMRepo.Migrations.EntitiesRelations do
  use Ecto.Migration

  def change do
    alter table(:divisions) do
      add(:legal_entity_id, references(:legal_entities, type: :uuid, on_delete: :nothing))
    end

    alter table(:medical_service_providers) do
      add(:legal_entity_id, references(:legal_entities, type: :uuid, on_delete: :nothing))
    end

    alter table(:legal_entities) do
      add(:capitation_contract_id, references(:medical_service_providers, type: :uuid, on_delete: :nothing))
    end

    create(index(:divisions, [:legal_entity_id]))
    create(index(:medical_service_providers, [:legal_entity_id]))
    create(index(:legal_entities, [:capitation_contract_id]))
  end
end
