defmodule Core.Repo.Migrations.AddUniqueIndexToMedicationRequestRequestNumber do
  use Ecto.Migration

  def change do
    create(index("medication_request_requests", [:number], unique: true))
  end
end
