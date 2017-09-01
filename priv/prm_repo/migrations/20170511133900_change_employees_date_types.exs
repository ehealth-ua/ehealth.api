defmodule EHealth.PRMRepo.Migrations.ChangeEmployeesDateTypes do
  use Ecto.Migration

  def change do
    alter table(:employees) do
      modify :start_date, :date, null: false
      modify :end_date, :date
    end
  end
end
