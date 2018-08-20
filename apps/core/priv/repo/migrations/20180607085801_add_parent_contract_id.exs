defmodule Core.Repo.Migrations.AddParentContractId do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:parent_contract_id, :uuid)
    end
  end
end
