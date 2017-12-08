defmodule EventManagerApi.Repo.Migrations.AddEventsPrimaryKey do
  use Ecto.Migration

  def change do
    alter table(:events) do
      modify :id, :uuid, primary_key: true
    end
  end
end
