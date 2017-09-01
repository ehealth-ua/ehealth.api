defmodule EHealth.PRMRepo.Migrations.SetMspAccreditationNullable do
  use Ecto.Migration

  def change do
    alter table(:medical_service_providers) do
      modify :accreditation, :map, null: true
    end
  end
end
