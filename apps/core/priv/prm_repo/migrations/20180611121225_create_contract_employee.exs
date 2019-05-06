defmodule Core.PRMRepo.Migrations.CreateContractEmployee do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:contract_employees, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:staff_units, :float, null: false)
      add(:declaration_limit, :integer, null: false)
      add(:employee_id, :uuid, null: false)
      add(:division_id, :uuid, null: false)
      add(:contract_id, references(:contracts, type: :uuid, on_delete: :nothing))
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)
      add(:start_date, :date, null: false)
      add(:end_date, :date)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
