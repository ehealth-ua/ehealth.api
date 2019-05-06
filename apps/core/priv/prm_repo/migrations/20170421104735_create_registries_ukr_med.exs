defmodule Core.PRMRepo.Migrations.CreatePRM.Registries.UkrMedRegistry do
  use Ecto.Migration

  def change do
    create table(:ukr_med_registries, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string)
      add(:edrpou, :string, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:ukr_med_registries, [:edrpou]))
  end
end
