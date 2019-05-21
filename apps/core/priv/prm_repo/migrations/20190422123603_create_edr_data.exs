defmodule Core.PRMRepo.Migrations.CreateEdrData do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("edr_data", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:edr_id, :integer, null: false)
      add(:name, :string, null: false)
      add(:short_name, :string)
      add(:public_name, :string, null: false)
      add(:state, :integer)
      add(:legal_form, :string)
      add(:edrpou, :string, null: false)
      add(:kveds, :map, null: false)
      add(:registration_address, :map, null: false)
      add(:is_active, :boolean, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps(type: :utc_datetime)
    end
  end
end
