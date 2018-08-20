defmodule Core.FraudRepo.Migrations.CreateInnms do
  use Ecto.Migration

  def change do
    create table(:innms, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:sctid, :string, null: true)
      add(:name, :string, null: false)
      add(:name_original, :string, null: false)
      add(:is_active, :boolean, default: false, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps(type: :utc_datetime)
    end
  end
end
