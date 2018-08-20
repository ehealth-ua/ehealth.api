defmodule Core.Repo.Migrations.AddDeclarationRequestChannel do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      add(:channel, :string)
    end

    execute("UPDATE declaration_requests SET channel = 'MIS';")

    alter table(:declaration_requests) do
      modify(:channel, :string, null: false)
    end
  end
end
