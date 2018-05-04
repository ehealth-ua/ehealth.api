defmodule EHealth.Repo.Migrations.DropContractRequestNhsSigned do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      remove(:nhs_signed)
    end
  end
end
