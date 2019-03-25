defmodule Core.PRMRepo.Migrations.AddDlsIdDivisions do
  use Ecto.Migration

  def change do
    alter table(:divisions) do
      add(:dls_id, :string, null: true)
      add(:dls_verified, :boolean, null: true)
    end
  end
end
