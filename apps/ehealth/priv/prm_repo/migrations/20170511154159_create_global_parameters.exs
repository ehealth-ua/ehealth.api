defmodule EHealth.PRMRepo.Migrations.CreatePRM.GlobalParameters.GlobalParameter do
  use Ecto.Migration

  def change do
    create table(:global_parameters, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:parameter, :string, null: false)
      add(:value, :string, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps()
    end
  end
end
