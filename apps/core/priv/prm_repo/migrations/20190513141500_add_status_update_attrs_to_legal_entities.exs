defmodule Core.PRMRepo.Migrations.AddStatusUpdateAttrsToLegalEntities do
  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add(:status_reason, :text)
      add(:reason, :text)
    end
  end
end
