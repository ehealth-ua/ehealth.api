defmodule Core.Repo.Migrations.AddContractRequestType do
  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:type, :string, null: false, default: "CAPITATION")
      add(:medical_program_id, :uuid)
    end

    execute("ALTER TABLE contract_requests ALTER COLUMN type DROP DEFAULT;")
  end
end
