defmodule Core.FraudRepo.Migrations.AddDeclarationNumberToDeclarations do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add(:declaration_number, :string)
    end
  end
end
