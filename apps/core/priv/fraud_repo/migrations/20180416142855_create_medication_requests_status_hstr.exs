defmodule OPS.Repo.Migrations.CreateMedicationRequestsStatusHstr do
  use Ecto.Migration

  def up do
    create table(:medication_requests_status_hstr, primary_key: false) do
      add :id, :integer, null: false
      add :medication_request_id, :uuid, null: false
      add :status, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end
  end

  def down do
    drop table(:medication_requests_status_hstr)
  end
end
