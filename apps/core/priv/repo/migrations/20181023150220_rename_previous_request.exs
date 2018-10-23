defmodule Core.Repo.Migrations.RenamePreviousRequest do
  @moduledoc false

  use Ecto.Migration

  def change do
    rename(table(:contract_requests), :previous_request, to: :previous_request_id)
  end
end
