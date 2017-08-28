defmodule EHealth.Repo.Migrations.AddDeclarationIdGenerationToDeclarationRequests do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS \“uuid-ossp\”;"
    alter table(:declaration_requests) do
      modify :declaration_id, :uuid, default: fragment("uuid_generate_v4()")
    end
  end
end
