defmodule Core.PRMRepo.Migrations.LegalEntityLicenseId do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add(:license_id, references(:licenses, type: :uuid, on_delete: :nothing))
    end
  end
end
