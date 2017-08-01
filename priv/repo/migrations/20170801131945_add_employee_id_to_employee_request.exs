defmodule EHealth.Repo.Migrations.AddEmployeeIdToEmployeeRequest do
  use Ecto.Migration

  def change do
    alter table(:employee_requests) do
      add :employee_id, :uuid
    end
  end
end
