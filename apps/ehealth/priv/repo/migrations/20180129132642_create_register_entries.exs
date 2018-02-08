defmodule EHealth.Repo.Migrations.CreateRegisterEntries do
  use Ecto.Migration

  def change do
    create table(:register_entries, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:tax_id, :string)
      add(:national_id, :string)
      add(:passport, :string)
      add(:birth_certificate, :string)
      add(:temporary_certificate, :string)
      add(:status, :string, null: false)
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid)
      add(:person_id, :uuid)

      add(:register_id, references(:registers, type: :uuid, on_delete: :nothing))

      timestamps()
    end
  end
end