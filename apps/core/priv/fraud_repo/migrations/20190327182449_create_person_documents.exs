defmodule Core.FraudRepo.Migrations.CreatePersonDocuments do
  use Ecto.Migration

  def change do
    create table(:person_documents, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:person_id, :uuid, references: :persons, type: :uuid)
      add(:type, :text)
      add(:number, :text)
      add(:issued_at, :string)
      add(:expiration_date, :string)
      add(:issued_by, :text)

      timestamps(type: :utc_datetime)
    end
  end
end
