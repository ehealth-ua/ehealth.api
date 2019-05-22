defmodule Core.Repo.Migrations.UpdateSchedulerIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    DROP INDEX IF EXISTS declaration_requests_inserted_at_status_index;
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS declaration_requests_expired_idx ON
    declaration_requests (inserted_at DESC) WHERE status <> 'SIGNED' or status <> 'EXPIRED';
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS declaration_requests_signed_idx ON
    declaration_requests (inserted_at DESC) WHERE status  = 'SIGNED' AND data is not null;
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS  mrr_autoterminate_idx ON
    medication_request_requests(inserted_at)  WHERE status  = 'NEW';
    """)
  end
end
