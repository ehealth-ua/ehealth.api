defmodule Core.PRMRepo.Migrations.ChangeContractsStatusReasonColumnType do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      modify(:status_reason, :text)
    end
  end
end
