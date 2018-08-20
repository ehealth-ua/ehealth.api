defmodule Core.Repo.Migrations.AddEmployeeRequestStatus do
  use Ecto.Migration

  def change do
    alter table(:employee_requests) do
      add(:status, :string)
    end
  end
end
