defmodule Core.Repo.Migrations.AddContractRequestType do
  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:contract_type, :string, null: false, default: "CAPITATION")
      add(:program_id, :uuid)
    end

    execute("ALTER TABLE contract_requests ALTER COLUMN contract_type DROP DEFAULT;")
  end
end
