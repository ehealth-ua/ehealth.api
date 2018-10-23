defmodule Core.Repo.Migrations.AddAssigneeIdToContractRequests do
  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:assignee_id, :uuid)
    end
  end
end
