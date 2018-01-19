defmodule EHealth.PRMRepo.Migrations.AddOptionalFieldsToLegalEntity do
  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add(:archive, :map, null: true)
      add(:website, :string, null: true)
      add(:beneficiary, :string, null: true)
      add(:receiver_funds_code, :string, null: true)
    end
  end
end
