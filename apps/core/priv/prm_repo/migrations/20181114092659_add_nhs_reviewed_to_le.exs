defmodule Core.PRMRepo.Migrations.AddNhsReviewedToLe do
  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add(:nhs_reviewed, :boolean, default: false)
    end
  end
end
