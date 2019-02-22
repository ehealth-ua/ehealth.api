defmodule Core.PRMRepo.Migrations.AddDailyDosageToMedications do
  use Ecto.Migration

  def change do
    alter table(:medications) do
      add(:daily_dosage, :float)
    end
  end
end
