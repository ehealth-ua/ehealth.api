defmodule Core.Repo.Migrations.AddPreviousRequestFkey do
  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      modify(:previous_request_id, references(:contract_requests, type: :uuid))
    end
  end
end
