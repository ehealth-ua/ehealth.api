defmodule Core.FraudRepo.Migrations.CreateBlackListUsers do
  use Ecto.Migration

  def change do
    create table(:black_list_users, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:tax_id, :string, null: false)
      add(:is_active, :boolean, default: false, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps()
    end
  end
end
