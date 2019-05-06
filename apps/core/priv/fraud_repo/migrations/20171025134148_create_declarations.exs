defmodule Core.FraudRepo.Migrations.CreateDeclarations do
  use Ecto.Migration

  def change do
    create table(:declarations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:employee_id, :uuid, null: false)
      add(:person_id, :uuid, null: false)
      add(:start_date, :date, null: false)
      add(:end_date, :date, null: false)
      add(:status, :string, null: false)
      add(:signed_at, :utc_datetime, null: false)
      add(:created_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)
      add(:is_active, :boolean, default: false)
      add(:scope, :string, null: false)
      add(:division_id, :uuid, null: false)
      add(:legal_entity_id, :uuid, null: false)
      add(:declaration_request_id, :uuid, null: false)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
