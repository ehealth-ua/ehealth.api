defmodule Core.PRMRepo.Migrations.ContractEmployeesDatetimes do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_employees) do
      modify(:start_date, :utc_datetime_usec, null: false)
      modify(:end_date, :utc_datetime_usec)
    end
  end
end
