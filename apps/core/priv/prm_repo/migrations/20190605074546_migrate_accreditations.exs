defmodule Core.PRMRepo.Migrations.MigrateAccreditations do
  use Ecto.Migration

  def change do
    execute("""
      UPDATE legal_entities
      SET accreditation = medical_service_providers.accreditation,
      updated_at = now()
      FROM medical_service_providers
      WHERE legal_entities.id = medical_service_providers.legal_entity_id
      AND legal_entities.accreditation IS NULL;
    """)
  end
end
