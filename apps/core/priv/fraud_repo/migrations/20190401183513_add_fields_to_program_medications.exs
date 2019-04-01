defmodule Core.FraudRepo.Migrations.AddFieldsToProgramMedications do
  use Ecto.Migration

  def change do
    alter table(:program_medications) do
      add(:wholesale_price, :float)
      add(:consumer_price, :float)
      add(:reimbursement_daily_dosage, :float)
      add(:estimated_payment_amount, :float)
    end
  end
end
