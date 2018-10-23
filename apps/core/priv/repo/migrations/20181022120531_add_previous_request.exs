defmodule Core.Repo.Migrations.AddPreviousRequest do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:previous_request, :uuid, null: true)
    end
  end
end
