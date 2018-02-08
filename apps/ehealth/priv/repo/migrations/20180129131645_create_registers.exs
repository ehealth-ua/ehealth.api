defmodule EHealth.Repo.Migrations.CreateRegisters do
  use Ecto.Migration

  def change do
    create table(:registers, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:file_name, :string, null: false)
      add(:type, :string, null: false)
      add(:status, :string, null: false)
      add(:qty, :map, default: %{total: 0, errors: 0, not_found: 0, processing: 0})
      add(:errors, :map)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid)

      timestamps()
    end
  end
end
