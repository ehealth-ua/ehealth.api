defmodule Core.PRMRepo.Migrations.CreateEdrVerifications do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:edr_verifications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:status_code, :integer)
      add(:edr_status, :string)
      add(:legal_entity_id, :uuid, null: false)
      add(:edr_data, :map)
      add(:legal_entity_data, :map)
      add(:edr_state, :integer)
      add(:error_message, :text)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end
  end
end
