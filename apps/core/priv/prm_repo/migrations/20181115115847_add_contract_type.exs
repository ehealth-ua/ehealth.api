defmodule Core.Repo.Migrations.AddContractType do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add(:type, :string, null: false, default: "CAPITATION")
      add(:medical_program_id, :uuid)
    end

    execute("ALTER TABLE contracts ALTER COLUMN type DROP DEFAULT;")
  end
end
