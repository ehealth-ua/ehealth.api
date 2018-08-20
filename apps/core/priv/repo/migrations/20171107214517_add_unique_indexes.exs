defmodule Core.Repo.Migrations.AddUniqueIndexes do
  use Ecto.Migration

  def change do
    create(unique_index(:declaration_requests, [:declaration_id], where: "declaration_id IS NOT NULL"))
  end
end
