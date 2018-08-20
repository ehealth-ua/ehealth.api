defmodule Core.Repo.Migrations.DeclarationRequestsChangeIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  def change do
    execute(
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS declaration_requests_inserted_at_status_index ON declaration_requests(inserted_at desc, status);"
    )

    execute("DROP INDEX CONCURRENTLY IF EXISTS declaration_requests_status_inserted_at_index;")

    execute("DROP INDEX CONCURRENTLY IF EXISTS data_legal_entity_id_index;")

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS data_legal_entity_id_inserted_at_index
    ON public.declaration_requests (cast(data->'legal_entity'->>'id' as text), inserted_at desc);
    """)
  end
end
