defmodule Core.Repo.Migrations.AddDeclarationRequestsIndex do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    execute("""
    CREATE OR REPLACE FUNCTION date_part_immutable(jsonb)
    RETURNS numeric AS
    $BODY$
    select cast(date_part('year', to_timestamp($1->>'start_date', 'YYYY-MM-DD') AT TIME ZONE 'UTC') as numeric);
    $BODY$
    LANGUAGE sql
    immutable;
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS cabinet_declaration_req_index
    ON declaration_requests (
      mpi_id,
      status,
      date_part_immutable(data)
    );
    """)
  end
end
