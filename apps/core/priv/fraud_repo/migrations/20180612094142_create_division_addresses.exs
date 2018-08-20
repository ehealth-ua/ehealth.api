defmodule Core.FraudRepo.Migrations.CreateDivisionAddresses do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:division_addresses, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:division_id, references(:divisions, type: :uuid, on_delete: :restrict))
      add(:zip, :string)
      add(:area, :string)
      add(:type, :string)
      add(:region, :string)
      add(:street, :string)
      add(:country, :string)
      add(:building, :string)
      add(:apartment, :string)
      add(:settlement, :string)
      add(:street_type, :string)
      add(:settlement_id, :uuid)
      add(:settlement_type, :string)
    end

    create(index(:division_addresses, [:area]))
  end
end
