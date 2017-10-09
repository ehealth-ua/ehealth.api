defmodule EHealth.Repo.Migrations.CreateMedicationRequestRequests do
  use Ecto.Migration

  def change do
    create table(:medication_request_requests, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :data, :map, null: false
      add :number, :string, null: false
      add :status, :string, null: false
      add :inserted_by, :uuid, null: false
      add :updated_by, :uuid, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
