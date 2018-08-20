defmodule Core.Repo.Migrations.AddDeclarationRequestsStatusInsertedAtIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  def change do
    execute(
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS declaration_requests_status_inserted_at_index ON declaration_requests(status, inserted_at desc)"
    )
  end
end
