defmodule Core.PRMRepo.Migrations.UniqueContractRequestId do
  @moduledoc false

  use Ecto.Migration

  def change do
    create(unique_index("contracts", [:contract_request_id]))
  end
end
