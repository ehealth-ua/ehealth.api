defmodule EHealth.PRMRepo.Migrations.CreateSubstances do
  use Ecto.Migration

  def change do
    create table(:substances, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:sctid, :string, null: false)
      add(:name, :string, null: false)
      add(:name_original, :string, null: false)
      add(:is_active, :boolean, default: false, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:substances, [:sctid]))
  end
end
