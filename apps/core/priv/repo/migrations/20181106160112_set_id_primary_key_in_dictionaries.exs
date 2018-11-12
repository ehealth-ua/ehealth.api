defmodule Core.Repo.Migrations.SetIdPrimaryKeyInDictionaries do
  use Ecto.Migration

  alias Core.Dictionaries.Dictionary
  alias Core.Repo
  alias Ecto.UUID

  @disable_ddl_transaction true

  def change do
    Dictionary
    |> Repo.all()
    |> Enum.each(&execute("UPDATE dictionaries SET id = '#{UUID.generate()}' WHERE name='#{&1.name}';"))

    execute("ALTER TABLE dictionaries DROP CONSTRAINT IF EXISTS dictionaries_pkey")
    create unique_index(:dictionaries, :name, name: :dictionaries_name_uniq)

    alter table(:dictionaries) do
      modify(:id, :uuid, primary_key: true)
    end
  end
end
