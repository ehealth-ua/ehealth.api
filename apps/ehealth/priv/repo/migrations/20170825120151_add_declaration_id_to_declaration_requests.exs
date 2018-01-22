defmodule EHealth.Repo.Migrations.AddDeclarationIdToDeclarationRequests do
  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      add(:declaration_id, :uuid)
    end
  end
end
