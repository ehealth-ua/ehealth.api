defmodule EventManagerApi.Repo.Migrations.ChangeEventId do
  use Ecto.Migration

  def change do
    execute("""
      ALTER TABLE events DROP CONSTRAINT events_pkey;
    """)

    alter table(:events) do
      remove(:id)
      add(:id, :uuid)
    end
  end
end
