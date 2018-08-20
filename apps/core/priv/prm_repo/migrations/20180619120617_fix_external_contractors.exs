defmodule Core.PRMRepo.Migrations.FixExternalContractors do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute("""
    ALTER TABLE contracts ALTER COLUMN external_contractors TYPE JSONB USING (to_json(external_contractors))
    """)
  end
end
