defmodule Core.PRMRepo.Migrations.ContractsEndDateIndexes do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    create(index(:contracts, ["end_date DESC"]))
  end
end
