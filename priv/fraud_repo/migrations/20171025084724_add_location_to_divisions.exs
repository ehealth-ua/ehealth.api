defmodule EHealth.FraudRepo.Migrations.AddLocationToDivisions do
  use Ecto.Migration

  def change do
    alter table(:divisions) do
      add :location, :geometry
    end
  end
end
