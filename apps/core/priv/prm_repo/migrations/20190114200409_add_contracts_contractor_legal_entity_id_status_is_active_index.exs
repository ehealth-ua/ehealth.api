defmodule Core.PRMRepo.Migrations.AddContractsContractorLegalEntityIdStatusIsActiveIndex do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS contracts_contractor_legal_entity_id_status_is_active_index
    ON contracts (
      contractor_legal_entity_id,
      status,
      is_active
    );
    """)
  end
end
