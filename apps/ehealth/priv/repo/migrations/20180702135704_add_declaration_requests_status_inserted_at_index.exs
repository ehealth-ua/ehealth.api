defmodule EHealth.Repo.Migrations.AddDeclarationRequestsStatusInsertedAtIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  def change do
    create(index(:declaration_requests, [:status, :inserted_at], concurrently: true))
  end
end
