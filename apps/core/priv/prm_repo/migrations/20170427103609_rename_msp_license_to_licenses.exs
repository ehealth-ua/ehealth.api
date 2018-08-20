defmodule Core.PRMRepo.Migrations.RenameMspLicenseToLicenses do
  use Ecto.Migration

  def change do
    rename(table(:medical_service_providers), :license, to: :licenses)
  end
end
