defmodule Core.PRMRepo.Migrations.AddNhsUnverifiedAtToLegalEntities do
  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add(:nhs_unverified_at, :utc_datetime_usec)
    end
  end
end
