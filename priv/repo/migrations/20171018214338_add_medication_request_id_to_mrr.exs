defmodule EHealth.Repo.Migrations.AddMedicationRequestIdToMrr do
  use Ecto.Migration

  def change do
    alter table(:medication_request_requests) do
      add(:medication_request_id, :uuid)
    end

    execute("UPDATE medication_request_requests SET medication_request_id = id")

    alter table(:medication_request_requests) do
      modify(:medication_request_id, :uuid, null: false)
    end

    create(unique_index(:medication_request_requests, [:medication_request_id]))
  end
end
