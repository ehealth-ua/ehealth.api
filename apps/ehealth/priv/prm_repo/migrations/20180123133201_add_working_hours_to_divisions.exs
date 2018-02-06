defmodule EHealth.PRMRepo.Migrations.AddWorkingHoursToDivisions do
  use Ecto.Migration

  def change do
    alter table(:divisions) do
      add(:working_hours, :map)
    end
  end
end
