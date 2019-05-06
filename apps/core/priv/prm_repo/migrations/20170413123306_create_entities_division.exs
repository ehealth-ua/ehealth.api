defmodule Core.PRMRepo.Migrations.CreatePRM.Entities.Division do
  use Ecto.Migration

  def change do
    create table(:divisions, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:external_id, :string)
      add(:name, :string, null: false)
      add(:type, :string, null: false)
      add(:mountain_group, :string)
      add(:address, :map, null: false)
      add(:phones, :map, null: false)
      add(:email, :string)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
