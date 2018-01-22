defmodule EHealth.PRMRepo.Migrations.AddUniqueIndexToParties do
  use Ecto.Migration

  def change do
    create(index(:parties, [:tax_id, :birth_date], unique: true))
  end
end
