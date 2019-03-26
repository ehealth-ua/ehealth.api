defmodule Core.PRMRepo.Migrations.UppercaseContractsStatusReason do
  use Ecto.Migration

  def change do
    execute("UPDATE contracts SET status_reason = UPPER(status_reason);")
  end
end
