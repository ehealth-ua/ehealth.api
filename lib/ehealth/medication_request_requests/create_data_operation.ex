defmodule EHealth.MedicationRequestRequest.CreateDataOperation do
  @moduledoc false
  import Ecto.Changeset
  import EHealth.MedicationRequestRequest.OperationHelpers

  alias EHealth.MedicationRequestRequest.Operation
  alias EHealth.MedicationRequestRequest.EmbeddedData

  @map_fields [:created_at, :started_at, :ended_at, :dispense_valid_from, :employee_id,
               :dispense_valid_to, :person_id, :division_id, :medication_id, :medication_qty]

  def create(data, client_id) do
    %EmbeddedData{}
    |> cast(data, @map_fields)
    |> Operation.new()
    |> validate_foreign_key(client_id, &get_legal_entity/1, &put_legal_entity/2)
    |> validate_foreign_key(data, &get_employee/1, &validate_employee/2, key: :employee)
    |> validate_foreign_key(data, &get_person/1, &validate_person/2, key: :person)
    |> validate_foreign_key(data, &get_division/1, &validate_division/2, key: :division)
    |> validate_data(data, &validate_dates/2)
    |> validate_data(data, &validate_declaration_existance/2)
    |> validate_data(data, &validate_medication_id/2, key: :medication)
  end
end
