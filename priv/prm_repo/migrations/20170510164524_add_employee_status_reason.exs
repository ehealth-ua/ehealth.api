defmodule EHealth.PRMRepo.Migrations.AddEmployeeStatusReason do
  use Ecto.Migration

  def change do
    alter table(:employees) do
      add :status_reason, :string
    end
  end
end
