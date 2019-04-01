defmodule Core.FraudRepo.Migrations.AddColumnsToParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add(:about_myself, :text)
      add(:working_experience, :integer)
      add(:declaration_limit, :integer)
    end
  end
end
