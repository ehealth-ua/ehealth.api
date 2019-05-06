defmodule Core.PRMRepo.Migrations.CreateProgramMedication do
  use Ecto.Migration

  def change do
    create table(:program_medications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:reimbursement, :map, null: false)
      add(:is_active, :boolean, null: false)
      add(:medication_request_allowed, :boolean, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      add(:medication_id, references(:medications, type: :uuid, on_delete: :nothing), null: false)
      add(:medical_program_id, references(:medical_programs, type: :uuid, on_delete: :nothing), null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:program_medications, [:medication_id, :medical_program_id]))
  end
end
