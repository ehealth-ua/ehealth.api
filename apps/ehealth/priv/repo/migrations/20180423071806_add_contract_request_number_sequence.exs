defmodule EHealth.Repo.Migrations.AddContractRequestNumberSequence do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute("CREATE SEQUENCE contract_request START 1000000;")
  end
end
