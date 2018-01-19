defmodule EHealth.Repo.Migrations.ChangePrintoutContentInDeclaraionRequest do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE declaration_requests ALTER COLUMN printout_content TYPE TEXT USING (printout_content#>>'{}')",
      "ALTER TABLE declaration_requests ALTER COLUMN printout_content TYPE JSONB USING (to_json(printout_content))"
    )
  end
end
