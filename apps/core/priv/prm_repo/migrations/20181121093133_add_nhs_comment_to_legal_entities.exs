defmodule Core.PRMRepo.Migrations.AddNhsCommentToLegalEntities do
  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add(:nhs_comment, :text, default: "")
    end
  end
end
