defmodule EHealth.PRMRepo.Migrations.AddedToDivisionIsActive do
  use Ecto.Migration

  def change do
    alter table(:divisions) do
      add(:is_active, :boolean, default: false, null: false)
    end
  end
end
