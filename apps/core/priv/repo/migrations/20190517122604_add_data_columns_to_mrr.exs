defmodule Core.Repo.Migrations.AddDataColumnsToMrr do
  use Ecto.Migration

  def change do
    alter table(:medication_request_requests) do
      add(:data_person_id, :uuid)
      add(:data_employee_id, :uuid)
      add(:data_intent, :string)
    end
  end
end
