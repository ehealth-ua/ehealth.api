defmodule Core.Repo.Migrations.DropDeclarationRequetsUnusedDbObjects do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("DROP INDEX IF EXISTS cabinet_declaration_req_index;")
    execute("DROP INDEX IF EXISTS create_declatation_req_index;")
    execute("DROP INDEX IF EXISTS data_legal_entity_id_inserted_at_index;")
    execute("DROP FUNCTION IF EXISTS date_part_immutable(jsonb);")
  end
end
