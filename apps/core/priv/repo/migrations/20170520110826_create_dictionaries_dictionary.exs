defmodule Core.Repo.Migrations.CreatePRM.Dictionaries.Dictionary do
  use Ecto.Migration

  def change do
    create table(:dictionaries, primary_key: false) do
      add(:name, :string, primary_key: true)
      add(:values, :map, null: false)
      add(:labels, :map, null: false)
      add(:is_active, :boolean, default: false, null: false)
    end
  end
end
