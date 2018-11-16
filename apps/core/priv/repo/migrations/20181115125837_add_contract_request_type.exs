defmodule Core.Repo.Migrations.AddContractRequestType do
  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:contract_type, :string, null: false)
      add(:program_id, :uuid)
    end
  end
end
