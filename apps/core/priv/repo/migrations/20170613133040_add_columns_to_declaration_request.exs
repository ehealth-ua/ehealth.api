defmodule Core.Repo.Migrations.AddColumnsToDeclarationRequest do
  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      add(:authentication_method_current, :jsonb, null: false)
      add(:documents, :jsonb, null: false)
      add(:printout_content, :jsonb, null: false)
      add(:updated_by, :uuid, null: false)
    end
  end
end
