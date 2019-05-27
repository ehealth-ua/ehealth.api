defmodule Core.PRMRepo.Migrations.CreateProgramServicesTable do
  use Ecto.Migration

  def change do
    create table(:program_services, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:program_id, references(:medical_programs, type: :uuid), null: false)
      add(:service_id, references(:services, type: :uuid))
      add(:service_group_id, references(:service_groups, type: :uuid))
      add(:consumer_price, :float, null: false)
      add(:description, :text)
      add(:is_active, :boolean, null: false)
      add(:request_allowed, :boolean, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
