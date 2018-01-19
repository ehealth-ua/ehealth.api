defmodule EHealth.PRMRepo.Migrations.CreatePRM.Entities.LegalEntity do
  use Ecto.Migration

  def change do
    create table(:legal_entities, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:short_name, :string)
      add(:public_name, :string)
      add(:status, :string, null: false)
      add(:type, :string, null: false)
      add(:owner_property_type, :string, null: false)
      add(:legal_form, :string, null: false)
      add(:edrpou, :string, null: false)
      add(:kveds, :map, null: false)
      add(:addresses, :map, null: false)
      add(:phones, :map)
      add(:email, :string)
      add(:is_active, :boolean, default: false, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps()
    end
  end
end
