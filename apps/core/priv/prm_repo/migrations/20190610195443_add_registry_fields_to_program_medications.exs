defmodule Core.PRMRepo.Migrations.AddRegistryFieldsToProgramMedications do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    alter table(:program_medications) do
      add(:start_date, :date)
      add(:end_date, :date)
      add(:registry_number, :string)
    end

    drop_if_exists(unique_index(:program_medications, [:medication_id, :medical_program_id]))
  end
end
