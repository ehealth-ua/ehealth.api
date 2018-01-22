defmodule EHealth.MedicationRequestRequest.RejectOperation do
  @moduledoc false
  import EHealth.MedicationRequestRequest.OperationHelpers

  alias EHealth.MedicationRequestRequest.Operation

  def reject(changeset, mrr, client_id) do
    changeset
    |> Operation.new()
    |> validate_foreign_key(client_id, &get_legal_entity/1, &put_legal_entity/2)
    |> validate_foreign_key(mrr.data.employee_id, &get_employee/1, &validate_employee/2, key: :employee)
    |> validate_foreign_key(mrr.data.person_id, &get_person/1, &validate_person/2, key: :person)
    |> validate_foreign_key(mrr.data.division_id, &get_division/1, &validate_division/2, key: :division)
    |> validate_foreign_key(mrr.data.medication_id, &get_medication/1, fn _, e -> {:ok, e} end, key: :medication)
    |> validate_foreign_key(
      mrr.data.medical_program_id,
      &get_medical_program/1,
      fn _, e -> {:ok, e} end,
      key: :medical_program
    )
  end
end
