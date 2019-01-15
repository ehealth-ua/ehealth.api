defmodule Core.PRMRepo.Migrations.AddEmployeesLegalEntityIdStatusIsActiveIndex do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS employees_legal_entity_id_status_is_active_index
    ON employees (
      legal_entity_id,
      status,
      is_active
    );
    """)
  end
end
