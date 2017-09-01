defmodule EHealth.PRMRepo.Migrations.CreatePRM.Parties.Party do
  use Ecto.Migration

  def change do
    create table(:parties, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :first_name, :string, null: false
      add :second_name, :string
      add :last_name, :string, null: false
      add :birth_date, :date, null: false
      add :gender, :string, null: false
      add :tax_id, :string, null: false
      add :documents, :map
      add :phones, :map
      add :inserted_by, :uuid, null: false
      add :updated_by, :uuid, null: false

      timestamps()
    end
  end
end
