defmodule EventManagerApi.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add(:event_type, :text, null: false)
      add(:entity_type, :text, null: false)
      add(:entity_id, :uuid, null: false)
      add(:properties, :map, null: false)
      add(:event_time, :naive_datetime, null: false)
      add(:changed_by, :uuid, null: false)

      timestamps()
    end
  end
end
