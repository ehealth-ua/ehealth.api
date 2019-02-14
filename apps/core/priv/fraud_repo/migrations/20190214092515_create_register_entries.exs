defmodule Core.FraudRepo.Migrations.CreateRegisterEntries do
  use Ecto.Migration

  def change do
    create table(:register_entries, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:status, :string, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid)
      add(:person_id, :uuid)
      add(:document_type, :string, null: false)
      add(:document_number, :string, null: false)
      add(:register_id, :uuid)

      timestamps()
    end
  end
end
