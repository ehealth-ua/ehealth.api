defmodule Core.FraudRepo.Migrations.CreatePersonAddresses do
  use Ecto.Migration

  def change do
    create table(:person_addresses, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:person_id, :uuid, references: :persons, type: :uuid)
      add(:type, :string)
      add(:country, :text)
      add(:area, :text)
      add(:region, :text)
      add(:settlement, :text)
      add(:settlement_type, :text)
      add(:settlement_id, :uuid)
      add(:street_type, :text)
      add(:street, :text)
      add(:building, :text)
      add(:apartment, :text)
      add(:zip, :text)

      timestamps(type: :utc_datetime)
    end
  end
end
