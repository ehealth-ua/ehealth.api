defmodule Core.Repo.Migrations.MakeContractorEmployeeDivisionsNullable do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      modify(:contractor_employee_divisions, :map, null: true)
    end
  end
end
