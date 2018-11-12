defmodule Core.Repo.Migrations.SetIdPrimaryKeyInDictionaries do
  use Ecto.Migration

  def change do
    Core.Repo.update_all(Core.Dictionaries.Dictionary, [set: [id: Ecto.UUID.generate()]])

    execute("ALTER TABLE dictionaries DROP CONSTRAINT dictionaries_pkey")
    create unique_index(:dictionaries, :name, name: :dictionaries_name_uniq)

    flush()

    alter table(:dictionaries) do
      modify(:id, :uuid, primary_key: true)
    end
  end
end
