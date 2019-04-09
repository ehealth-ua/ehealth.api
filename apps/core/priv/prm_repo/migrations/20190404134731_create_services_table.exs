defmodule Core.PRMRepo.Migrations.CreateServicesTable do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("services", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:code, :string)
      add(:name, :string)
      add(:is_active, :boolean)
      add(:parent_id, :uuid)
      add(:category, :string)
      add(:is_composition, :boolean)
      add(:request_allowed, :boolean)
      add(:inserted_by, :uuid)
      add(:updated_by, :uuid)

      timestamps(type: :utc_datetime)
    end
  end
end
