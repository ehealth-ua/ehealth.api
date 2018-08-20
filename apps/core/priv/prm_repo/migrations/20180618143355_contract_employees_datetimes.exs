defmodule Core.PRMRepo.Migrations.ContractEmployeesDatetimes do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_employees) do
      modify(:start_date, :naive_datetime, null: false)
      modify(:end_date, :naive_datetime)
    end
  end
end
