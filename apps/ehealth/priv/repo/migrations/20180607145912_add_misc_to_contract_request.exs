defmodule EHealth.Repo.Migrations.AddMiscToContractRequest do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:misc, :text)
    end
  end
end
