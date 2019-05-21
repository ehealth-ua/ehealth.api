defmodule Core.PRMRepo.Migrations.LegalEntitySignedContents do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("legal_entity_signed_contents", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:filename, :string)
      add(:legal_entity_id, references(:legal_entities, type: :uuid, on_delete: :nothing))

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create(index(:legal_entity_signed_contents, [:legal_entity_id]))
  end
end
