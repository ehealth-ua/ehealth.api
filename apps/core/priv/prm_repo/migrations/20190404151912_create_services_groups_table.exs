defmodule Core.PRMRepo.Migrations.CreateServicesGroupsTable do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("services_groups", primary_key: false) do
      add(:service_id, references("services", type: :uuid, on_delete: :delete_all), primary_key: true)
      add(:service_group_id, references("service_groups", type: :uuid, on_delete: :delete_all), primary_key: true)
      add(:alias, :string)
      add(:inserted_by, :uuid)
      add(:updated_by, :uuid)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
