defmodule Core.Repo.Migrations.SetContractRequestPrintoutContentText do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      modify(:printout_content, :text)
    end
  end
end
