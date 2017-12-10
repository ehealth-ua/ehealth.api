defmodule EHealth.PRMRepo.Migrations.AddNoTaxIdToParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add :no_tax_id, :boolean, null: false
    end
  end
end
