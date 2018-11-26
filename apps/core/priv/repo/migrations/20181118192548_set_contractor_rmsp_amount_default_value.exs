defmodule Core.Repo.Migrations.SetContractorRmspAmountDefaultValue do
  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      modify(:contractor_rmsp_amount, :integer, null: true)
    end
  end
end
