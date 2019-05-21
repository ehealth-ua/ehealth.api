defmodule Core.Repo.Migrations.CopyToMrrDataColumns do
  use Ecto.Migration

  def change do
    execute("""
      UPDATE medication_request_requests
      SET
        data_person_id = cast(data ->> 'person_id' as uuid),
        data_employee_id = cast(data ->> 'employee_id' as uuid),
        data_intent = data ->> 'intent'
      WHERE data IS NOT NULL;
    """)
  end
end
