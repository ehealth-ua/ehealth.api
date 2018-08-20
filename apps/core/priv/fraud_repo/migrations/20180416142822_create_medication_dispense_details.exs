defmodule OPS.Repo.Migrations.CreateMedicationDispenseDetails do
  use Ecto.Migration

  def change do
    create table(:medication_dispense_details, primary_key: false) do
      add :id, :integer, null: false
      add :medication_id, :uuid, null: false
      add :medication_dispense_id, :uuid, null: false
      add :medication_qty, :float, null: false
      add :sell_price, :float, null: false
      add :reimbursement_amount, :float, null: false
      add :sell_amount, :float, null: false
      add :discount_amount, :float, null: false
    end
  end
end
