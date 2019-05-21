defmodule Core.PRMRepo.Migrations.LegalEntityChanges do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table("legal_entities") do
      modify(:name, :string, null: true)
      modify(:short_name, :string, null: true)
      modify(:public_name, :string, null: true)
      modify(:owner_property_type, :string, null: true)
      modify(:legal_form, :string, null: true)
      modify(:kveds, :map, null: true)
      add(:registration_address, :map, null: true)
      add(:residence_address, :map, null: true)
    end

    create(index(:legal_entities, [:edrpou, :type, :status], unique: true, where: "status = 'ACTIVE'"))
  end
end
