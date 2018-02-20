defmodule EHealth.PRMRepo.Migrations.AddEmployeeSpeciality do
  use Ecto.Migration

  def change do
    alter table(:employees) do
      add(:speciality, :map)
    end
  end
end
