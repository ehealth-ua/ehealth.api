defmodule Core.Repo.Migrations.DeclarationRequestDropUnusedIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("DROP INDEX IF EXISTS cabinet_declaration_req_index;")
    execute("DROP INDEX IF EXISTS create_declatation_req_index;")
    execute("DROP INDEX IF EXISTS data_legal_entity_id_inserted_at_index;")
    execute("DROP INDEX IF EXISTS data_legal_entity_id_inserted_at_index_1;")
  end
end
