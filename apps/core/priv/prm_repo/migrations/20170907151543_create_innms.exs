defmodule Core.PRMRepo.Migrations.CreateInnms do
  use Ecto.Migration

  def change do
    create table(:innms, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:SCTID, :string, null: false)
      add(:name, :string, null: false)
      add(:is_active, :boolean, default: false, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:innms, [:SCTID]))
  end
end
