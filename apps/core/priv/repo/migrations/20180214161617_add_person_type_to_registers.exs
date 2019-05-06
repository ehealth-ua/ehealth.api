defmodule Core.Repo.Migrations.AddPersonTypeToRegisters do
  use Ecto.Migration

  def change do
    alter table(:registers) do
      add(:person_type, :string, null: false, default: "patient")
    end
  end
end
