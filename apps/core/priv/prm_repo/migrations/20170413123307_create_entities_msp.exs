defmodule Core.PRMRepo.Migrations.CreatePRM.Entities.MSP do
  use Ecto.Migration

  def change do
    create table(:medical_service_providers, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:accreditation, :map, null: false)
      add(:license, :map)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
