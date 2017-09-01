defmodule EHealth.PRMRepo.Migrations.AddLegalEntityCreatedViaMisClientId do
  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add :created_by_mis_client_id, :uuid
    end
  end
end
