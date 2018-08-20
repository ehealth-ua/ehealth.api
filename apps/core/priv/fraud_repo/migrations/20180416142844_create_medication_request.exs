defmodule OPS.Repo.Migrations.CreateMedicationRequest do
  use Ecto.Migration

  def change do
    create table(:medication_requests, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :request_number, :string, null: false
      add :created_at, :date, null: false
      add :started_at, :date, null: false
      add :ended_at, :date, null: false
      add :dispense_valid_from, :date, null: false
      add :dispense_valid_to, :date, null: false
      add :division_id, :uuid, null: false
      add :legal_entity_id, :uuid, null: false
      add :person_id, :uuid, null: false
      add :employee_id, :uuid, null: false
      add :medication_id, :uuid, null: false
      add :medication_qty, :float, null: false
      add :status, :string, null: false
      add :is_active, :boolean, null: false
      add :rejected_at, :date
      add :rejected_by, :uuid
      add :reject_reason, :string
      add :verification_code, :string
      add :medication_request_requests_id, :uuid, null: false
      add :medical_program_id, :uuid
      add :inserted_by, :uuid
      add :updated_by, :uuid

      timestamps()
    end
  end
end
