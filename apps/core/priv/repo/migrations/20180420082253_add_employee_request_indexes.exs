defmodule Core.Repo.Migrations.AddEmployeeRequestIndexes do
  @moduledoc false

  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    create(index(:employee_requests, [:status, :inserted_at], concurrently: true))
  end
end
