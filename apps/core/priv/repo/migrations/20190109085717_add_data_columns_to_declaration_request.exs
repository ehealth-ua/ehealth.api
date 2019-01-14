defmodule Core.Repo.Migrations.AddDataColumnsToDeclarationRequest do
  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      add(:data_legal_entity_id, :uuid)
      add(:data_employee_id, :uuid)
      add(:data_start_date_year, :integer)
      add(:data_person_tax_id, :string)
      add(:data_person_first_name, :string)
      add(:data_person_last_name, :string)
      add(:data_person_birth_date, :date)
    end
  end
end
