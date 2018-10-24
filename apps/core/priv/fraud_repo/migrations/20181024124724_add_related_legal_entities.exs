defmodule Core.FraudRepo.Migrations.AddRelatedLegalEntities do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:related_legal_entities, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:reason, :string)
      add(:merged_from_id, :uuid, null: false)
      add(:merged_to_id, :uuid, null: false)
      add(:is_active, :boolean, null: false)
      add(:inserted_by, :uuid, null: false)
      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
