defmodule Core.Repo.Migrations.AddMrrDataFieldsIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
      CREATE INDEX CONCURRENTLY IF NOT EXISTS data_person_id_index ON medication_request_requests (data_person_id);
    """)
  end

  def change do
    execute("""
      CREATE INDEX CONCURRENTLY IF NOT EXISTS data_employee_id_index ON medication_request_requests (data_employee_id);
    """)
  end

  def change do
    execute("""
      CREATE INDEX CONCURRENTLY IF NOT EXISTS data_intent_index ON medication_request_requests (data_intent);
    """)
  end

  def change do
    execute("""
      CREATE INDEX CONCURRENTLY IF NOT EXISTS status_index ON medication_request_requests (status);
    """)
  end
end
