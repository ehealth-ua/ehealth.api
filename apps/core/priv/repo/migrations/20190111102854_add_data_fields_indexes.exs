defmodule Core.Repo.Migrations.AddDataFieldsIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    create_if_not_exists(
      index(:declaration_requests, [:mpi_id, :status, :data_start_date_year], name: :cabinet_declaration_req_index)
    )

    create_if_not_exists(
      index(:declaration_requests, [:status, :data_employee_id, :data_legal_entity_id],
        name: :create_declatation_req_index
      )
    )

    create_if_not_exists(
      index(:declaration_requests, [:data_legal_entity_id, :inserted_at], name: :data_legal_entity_id_inserted_at_index)
    )

    create_if_not_exists(
      index(:declaration_requests, [:data_person_tax_id, :data_employee_id, :data_legal_entity_id, :status],
        name: :pending_declaration_requests_tax_id
      )
    )

    create_if_not_exists(
      index(
        :declaration_requests,
        [
          :data_person_birth_date,
          :data_person_last_name,
          :data_person_first_name,
          :data_employee_id,
          :data_legal_entity_id,
          :status
        ],
        name: :pending_declaration_requests_person_attrs
      )
    )
  end
end
