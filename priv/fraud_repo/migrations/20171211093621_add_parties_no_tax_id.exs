defmodule EHealth.FraudRepo.Migrations.AddPartiesNoTaxId do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add(:no_tax_id, :boolean, null: false, default: false)
    end
  end
end
