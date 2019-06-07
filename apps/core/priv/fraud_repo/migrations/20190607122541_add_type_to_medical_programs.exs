defmodule Core.FraudRepo.Migrations.AddTypeToMedicalPrograms do
  use Ecto.Migration

  def change do
    alter table(:medical_programs) do
      add(:type, :text, null: false)
    end
  end
end
