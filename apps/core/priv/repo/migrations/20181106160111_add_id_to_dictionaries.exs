defmodule Core.Repo.Migrations.AddIdToDictionaries do
  use Ecto.Migration

  def change do
    alter table(:dictionaries) do
      add(:id, :uuid)
    end
  end
end
