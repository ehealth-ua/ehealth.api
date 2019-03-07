defmodule Core.PRMRepo.Migrations.MoveContractsStatusReasonToReason do
  use Ecto.Migration

  def change do
    execute("UPDATE contracts SET reason = status_reason, status_reason = NULL WHERE status_reason NOT LIKE 'auto_%'")
  end
end
