defmodule Core.Repo.Migrations.DeclarationRequestsIndexFix do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS list_declatation_req_data_index
    ON declaration_requests (
    data_employee_id,
    status,
    inserted_at desc
    );
    """)

    execute("DROP INDEX IF EXISTS create_declatation_req_data_index;")

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS declaration_requests_legal_entity_status_index
    ON declaration_requests(data_legal_entity_id, status);
    """)
  end
end
