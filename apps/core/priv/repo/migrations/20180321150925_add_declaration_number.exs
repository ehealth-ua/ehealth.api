defmodule Core.Repo.Migrations.AddDeclarationNumber do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      add(:declaration_number, :string)
    end
  end
end
