defmodule Core.MedicationRequestRequest.PreloadFkOperation do
  @moduledoc false
  import Core.MedicationRequestRequest.OperationHelpers
  alias Core.MedicationRequestRequest.Operation

  def preload(mrr) do
    %Ecto.Changeset{}
    |> Operation.new()
    |> validate_foreign_key(mrr.data.legal_entity_id, &get_legal_entity/1, fn _, e -> {:ok, e} end, key: :legal_entity)
    |> validate_foreign_key(mrr.data.employee_id, &get_employee/1, fn _, e -> {:ok, e} end, key: :employee)
    |> validate_foreign_key(mrr.data.person_id, &get_person/1, fn _, e -> {:ok, e} end, key: :person)
    |> validate_foreign_key(mrr.data.division_id, &get_division/1, fn _, e -> {:ok, e} end, key: :division)
    |> validate_foreign_key(mrr.data.medication_id, &get_medication/1, fn _, e -> {:ok, e} end, key: :medication)
    |> validate_foreign_key(
      mrr.data.medical_program_id,
      &get_medical_program/1,
      fn _, e -> {:ok, e} end,
      key: :medical_program
    )
  end
end
