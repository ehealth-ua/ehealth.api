defmodule EHealth.PRMRepo.Migrations.AddUniqueIndexes do
  use Ecto.Migration

  def change do
    create(unique_index(:black_list_users, [:tax_id], where: "is_active = true"))

    create(
      unique_index(
        :employees,
        [:legal_entity_id, :employee_type],
        where: "is_active = true AND (employee_type = 'OWNER' OR employee_type = 'PHARMACY_OWNER')",
        name: :employees_legal_entity_id_active_owner_index
      )
    )

    create(unique_index(:global_parameters, [:parameter]))
    drop(index(:innms, [:sctid]))
    create(unique_index(:innms, [:sctid], where: "sctid IS NOT NULL AND is_active = true"))
  end
end
