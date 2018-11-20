defmodule Core.Repo.Migrations.AddContractType do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add(:contract_type, :string, null: false, default: "CAPITATION")
      add(:program_id, :uuid)
    end

    execute("ALTER TABLE contracts ALTER COLUMN contract_type DROP DEFAULT;")
  end
end
