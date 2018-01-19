defmodule EHealth.PRMRepo.Migrations.AddNhsVerifiedToLegalEntitiy do
  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add(:nhs_verified, :boolean, default: false, null: false)
    end
  end
end
