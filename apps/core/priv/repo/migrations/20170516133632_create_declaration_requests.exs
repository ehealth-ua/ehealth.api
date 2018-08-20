defmodule Core.Repo.Migrations.CreateDeclarationRequests do
  use Ecto.Migration

  def change do
    create table(:declaration_requests, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:data, :map, null: false)
      add(:status, :string, null: false)
      add(:inserted_by, :uuid, null: false)

      timestamps()
    end
  end
end
