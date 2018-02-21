defmodule EHealth.PRMRepo.Migrations.AddEmployeeSpeciality do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:employees) do
      add(:speciality, :map)
    end
  end
end
