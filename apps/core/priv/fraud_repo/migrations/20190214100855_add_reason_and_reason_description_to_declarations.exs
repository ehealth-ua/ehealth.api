defmodule Core.FraudRepo.Migrations.AddReasonAndReasonDescriptionToDeclarations do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add :reason, :string
      add :reason_description, :text
    end
  end
end
