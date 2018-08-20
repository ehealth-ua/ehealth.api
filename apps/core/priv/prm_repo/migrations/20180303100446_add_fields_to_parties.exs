defmodule Core.PRMRepo.Migrations.AddFieldsToParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add(:about_myself, :string)
      add(:working_experience, :integer)
    end
  end
end
