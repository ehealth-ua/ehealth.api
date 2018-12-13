defmodule Core.FraudRepo.Migrations.MedicationRequestUpdates do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:medication_requests) do
      add(:intent, :string)
      add(:category, :string)
      add(:context, :map)
      add(:dosage_instruction, {:array, :map})
    end
  end
end
