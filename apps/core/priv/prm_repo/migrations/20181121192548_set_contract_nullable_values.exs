defmodule Core.PRMRepo.Migrations.SetContractorRmspAmountDefaultValue do
  use Ecto.Migration

  def up do
    alter table(:contracts) do
      modify(:contractor_rmsp_amount, :integer, null: true)
      modify(:nhs_contract_price, :float, null: true)
    end
  end

  def down do
    alter table(:contracts) do
      modify(:contractor_rmsp_amount, :integer, null: false)
      modify(:nhs_contract_price, :float, null: false)
    end
  end
end
