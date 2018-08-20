defmodule Core.Repo.Migrations.FixContractRequestJsonFields do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      remove(:external_contractors)
      remove(:contractor_employee_divisions)

      add(:external_contractors, :map)
      add(:contractor_employee_divisions, :map, null: false)
    end
  end
end
