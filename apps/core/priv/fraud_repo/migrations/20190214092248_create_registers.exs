defmodule Core.FraudRepo.Migrations.CreateRegisters do
  use Ecto.Migration

  def change do
    create table(:registers, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:file_name, :string, null: false)
      add(:type, :string, null: false)
      add(:status, :string, null: false)
      add(:qty, :map)
      add(:errors, :map)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid)
      add(:entity_type, :string, null: false)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
