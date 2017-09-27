defmodule EHealth.PRMRepo.Migrations.RenameSubstancesToINNMUpdateIngredients do
  use Ecto.Migration

  def change do
    drop table(:ingredients)
    drop table(:substances)

    create table(:innms, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :sctid, :string, null: false
      add :name, :string, null: false
      add :name_original, :string, null: false
      add :is_active, :boolean, default: false, null: false
      add :inserted_by, :uuid, null: false
      add :updated_by, :uuid, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:innms, [:sctid])

    create table(:ingredients, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :dosage, :map, null: false
      add :is_primary, :boolean, default: false, null: false

      add :medication_child_id, references(:medications, type: :uuid, on_delete: :nothing), null: true
      add :innm_child_id, references(:innms, type: :uuid, on_delete: :nothing), null: true
      add :parent_id, references(:medications, type: :uuid, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
