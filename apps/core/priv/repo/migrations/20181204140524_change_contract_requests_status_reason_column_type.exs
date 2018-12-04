defmodule Core.Repo.Migrations.ChangeContractRequestsStatusReasonColumnType do
  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      modify(:status_reason, :text)
    end
  end
end
