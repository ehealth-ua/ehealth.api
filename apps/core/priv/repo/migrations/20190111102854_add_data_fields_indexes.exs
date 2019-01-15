defmodule Core.Repo.Migrations.AddDataFieldsIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS cabinet_declaration_req_index
    ON declaration_requests (
      mpi_id,
      status,
      data_start_date_year
    );
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS create_declatation_req_index
    ON declaration_requests (
      status,
      data_employee_id,
      data_legal_entity_id
    );
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS data_legal_entity_id_inserted_at_index
    ON declaration_requests (
      data_legal_entity_id,
      inserted_at
    );
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS pending_declaration_requests_tax_id
    ON declaration_requests (
      data_person_tax_id,
      data_employee_id,
      data_legal_entity_id,
      status
    );
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS pending_declaration_requests_person_attrs
    ON declaration_requests (
      data_person_birth_date,
      data_person_last_name,
      data_person_first_name,
      data_employee_id,
      data_legal_entity_id,
      status
    );
    """)
  end
end
