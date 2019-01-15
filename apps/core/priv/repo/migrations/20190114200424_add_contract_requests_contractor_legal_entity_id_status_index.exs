defmodule Core.Repo.Migrations.AddContractRequestsContractorLegalEntityIdStatusIndex do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS contract_requests_contractor_legal_entity_id_status_index
    ON contract_requests (
      contractor_legal_entity_id,
      status
    );
    """)
  end
end
