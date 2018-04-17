defmodule OPS.Repo.Migrations.CreateMedicationDispense do
  use Ecto.Migration

  def change do
    create table(:medication_dispenses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :medication_request_id, :uuid, null: false
      add :dispensed_at, :date, null: false
      add :party_id, :uuid, null: false
      add :legal_entity_id, :uuid, null: false
      add :division_id, :uuid, null: false
      add :medical_program_id, :uuid
      add :payment_id, :string
      add :status, :string, null: false
      add :is_active, :boolean, null: false
      add :inserted_by, :uuid, null: false
      add :updated_by, :uuid, null: false
      add(:dispensed_by, :string)

      timestamps()
    end
  end
end
