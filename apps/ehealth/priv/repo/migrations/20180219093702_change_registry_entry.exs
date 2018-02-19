defmodule EHealth.Repo.Migrations.ChangeRegistryEntry do
  use Ecto.Migration

  def change do
    alter table(:register_entries) do
      add(:document_type, :string, null: false)
      add(:document_number, :string, null: false)
    end

    alter table(:register_entries) do
      remove(:tax_id)
      remove(:passport)
      remove(:national_id)
      remove(:birth_certificate)
      remove(:temporary_certificate)
    end
  end
end
