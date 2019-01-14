defmodule Core.Repo.Migrations.CopyToDeclarationRequestDataColumns do
  use Ecto.Migration

  def change do
    execute("""
      UPDATE declaration_requests
      SET
        data_legal_entity_id = cast(data -> 'legal_entity' ->> 'id' as uuid),
        data_employee_id = cast(data -> 'employee' ->> 'id' as uuid),
        data_start_date_year = cast(date_part('year', to_timestamp(data ->> 'start_date', 'YYYY-MM-DD') AT TIME ZONE 'UTC') as numeric),
        data_person_tax_id = data -> 'person' ->> 'tax_id',
        data_person_first_name = data -> 'person' ->> 'first_name',
        data_person_last_name = data -> 'person' ->> 'last_name',
        data_person_birth_date = cast(data -> 'person' ->> 'birth_date' as date)
      WHERE data IS NOT NULL;
    """)
  end
end
