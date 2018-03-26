defmodule EHealth.Repo.Migrations.AddDeclarationRequestDataIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute("""
    CREATE INDEX "data_legal_entity_id_index"
    ON public.declaration_requests (cast(data->'legal_entity'->>'id' as text));
    """)
  end
end
