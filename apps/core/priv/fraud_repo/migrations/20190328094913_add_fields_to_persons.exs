defmodule Core.FraudRepo.Migrations.AddFieldsToPersons do
  use Ecto.Migration

  def change do
    alter table(:persons) do
      add(:invalid_tax_id, :boolean)
      add(:no_tax_id, :boolean)
      add(:preferred_way_communication, :string)
      add(:unzr, :string)
      add(:version, :string)
    end
  end
end
