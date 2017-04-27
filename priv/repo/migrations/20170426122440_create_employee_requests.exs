defmodule EHealth.Repo.Migrations.AddEmployeeRequests do
  use Ecto.Migration

  def change do
    create table(:employee_requests, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :data, :map, null: false

      timestamps()
    end
  end
end
