defmodule Core.Repo.Migrations.CopyToDeclarationRequestDataColumns do
  use Ecto.Migration

  if Code.ensure_loaded?(Core.DeclarationRequests.DeclarationRequestTemp) do
    @disable_ddl_transaction true

    def change do
      create table(:declaration_requests_temp) do
        add(:last_inserted_at, :naive_datetime)
      end

      create(index(:declaration_requests, [:inserted_at]))
    end
  end
end
