defmodule Core.Repo.Migrations.RemoveDocumentsAsRequired do
  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      modify(:documents, :jsonb, null: true)
    end
  end
end
