defmodule Core.FraudRepo.Migrations.ChangeMedicationRequestDispenseValidFromNullable do
  use Ecto.Migration

  def change do
    alter table(:medication_requests) do
      modify(:dispense_valid_from, :date, null: true)
    end
  end
end
