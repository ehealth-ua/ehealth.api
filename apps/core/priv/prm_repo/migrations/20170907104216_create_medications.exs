defmodule Core.PRMRepo.Migrations.CreateMedications do
  use Ecto.Migration

  def change do
    create table(:medications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:type, :string, null: false)
      add(:manufacturer, :map)
      add(:code_atc, :string)
      add(:is_active, :boolean, default: false, null: false)
      add(:form, :string)
      add(:container, :map)
      add(:package_qty, :integer)
      add(:package_min_qty, :integer)
      add(:certificate, :string)
      add(:certificate_expired_at, :date)
      add(:ingredients, :map)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
