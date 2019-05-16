defmodule Core.PRMRepo.Migrations.CreateUniqueIndexContractNumberStatus do
  use Ecto.Migration

  def change do
    create(unique_index(:contracts, [:contract_number], where: "status = 'VERIFIED'", name: :contract_number_status_verified_index))
  end
end
