defmodule Core.FraudRepo.Migrations.CreateEmployeeRequests do
  use Ecto.Migration

  def change do
    create table(:employee_requests, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:status, :string)
      add(:employee_id, :uuid)

      timestamps()
    end
  end
end
