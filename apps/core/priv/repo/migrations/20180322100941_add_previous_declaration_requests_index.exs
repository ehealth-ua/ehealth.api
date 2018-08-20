defmodule Core.Repo.Migrations.AddPreviousDeclarationRequestsIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute("""
    CREATE INDEX "create_declatation_req_index"
    ON declaration_requests (
      status,
      cast("data"->'employee'->>'id' AS text),
      cast("data"->'legal_entity' ->> 'id' as text)
    );
    """)
  end
end
