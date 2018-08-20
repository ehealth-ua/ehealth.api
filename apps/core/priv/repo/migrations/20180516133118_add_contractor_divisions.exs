defmodule Core.Repo.Migrations.AddContractorDivisions do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:contractor_divisions, {:array, :uuid}, null: false)
    end
  end
end
