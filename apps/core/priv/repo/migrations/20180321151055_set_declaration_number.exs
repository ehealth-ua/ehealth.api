defmodule Core.Repo.Migrations.SetDeclarationNumber do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute("UPDATE declaration_requests SET declaration_number = declaration_id")

    alter table(:declaration_requests) do
      modify(:declaration_number, :string, null: false)
    end

    create(unique_index(:declaration_requests, [:declaration_number]))
  end
end
