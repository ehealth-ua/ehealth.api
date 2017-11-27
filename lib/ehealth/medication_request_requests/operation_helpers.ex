defmodule EHealth.MedicationRequestRequest.OperationHelpers do
  @moduledoc false
  import Ecto.Changeset

  alias EHealth.Employees
  alias EHealth.LegalEntities
  alias EHealth.Divisions
  alias EHealth.MedicationRequestRequest.Validations
  alias EHealth.Utils.Helpers
  alias EHealth.API.MPI
  alias EHealth.MedicationRequestRequest.Operation
  alias EHealth.Medications
  alias EHealth.MedicalPrograms

  def get_employee(id) do
    Helpers.get_assoc_by_func("employee_id", fn -> Employees.get_by_id(id) end)
  end

  def get_medication(id) do
    Helpers.get_assoc_by_func("medication_id", fn -> Medications.get_innm_dosage_by_id(id) end)
  end

  def get_medical_program(nil), do: {:ok, nil}
  def get_medical_program(id) do
    Helpers.get_assoc_by_func("medical_program_id", fn -> MedicalPrograms.get_by_id(id) end)
  end

  def validate_employee(operation, employee) do
    Validations.validate_doctor(employee, operation.data.legal_entity)
  end

  def get_person(id) do
    Helpers.get_assoc_by_func("person_id", fn -> MPI.person(id) end)
  end

  def get_legal_entity(client_id) do
    case LegalEntities.get_by_id(client_id) do
      nil -> {:error, "client_id"}
      le -> {:ok, le}
    end
  end

  def put_legal_entity(operation, le) do
    operation =
      operation
      |> Operation.call_changeset(&Ecto.Changeset.put_change/3, [:legal_entity_id, le.id])
      |> Operation.add_data(:legal_entity, le)
    {:ok, operation}
  end

  def validate_declaration_existance(operation, _data) do
    Validations.validate_declaration_existance(operation.data.employee, operation.data.person)
  end

  def validate_medication_id(_operation, data) do
    Validations.validate_medication_id(data["medication_id"], data["medication_qty"], data["medical_program_id"])
  end

  def validate_person(_operation, person) do
    Validations.validate_person(person)
  end

  def get_division(id) do
    Helpers.get_assoc_by_func("division_id", fn -> Divisions.get_by_id(id) end)
  end

  def validate_division(operation, division) do
    Validations.validate_divison(division, operation.data.legal_entity.id)
  end

  def validate_dates(_operation, data) do
    Validations.validate_dates(data)
  end

  def validate_foreign_key(operation, data, fetch_function, validate_function, opts \\ [])
  def validate_foreign_key(%Operation{valid?: false} = operation, _data, _fetch_function, _validate_function, _opts) do
    operation
  end
  def validate_foreign_key(%Operation{valid?: true} = operation, data, fetch_function, validate_function, opts) do
    case apply(fetch_function, [data]) do
      {:ok, {:ok, %{"data" => collection}}} -> validate_data(operation, collection, validate_function, opts)
      {:ok, entity} -> validate_data(operation, entity, validate_function, opts)
      {:assoc_error, field} -> fk_error(operation, field)
    end
  end

  def validate_data(operation, data, validate_function, opts \\ [])
  def validate_data(%Operation{valid?: false} = operation, _data, _validate_function, _opts) do
    operation
  end
  def validate_data(%Operation{valid?: true} = operation, data, validate_function, opts) do
    case apply(validate_function, [operation, data]) do
      {:ok, %Operation{} = operation} -> operation
      {:ok, entity} ->
        if opts[:key] do
          Operation.add_data(operation, opts[:key], entity)
        else
          operation
        end
      {:error, %Operation{} = operation} -> operation
      {error_name, error_obj} -> custom_errors({error_name, error_obj}, operation)
    end
  end

  def fk_error(operation, field) do
    error = [String.to_atom(field), "#{Helpers.from_filed_to_name(field)} not found", [validation: :required]]

    operation
    |> Operation.call_changeset(&add_error/4, error)
    |> Map.put(:valid?, false)
  end

  def custom_errors(error_tuple, operation) when is_tuple(error_tuple) do
    operation =
      case error_tuple do
        {:invalid_employee, _} ->
          Operation.call_changeset(operation, &add_error/4, [:"employee_id",
            "Only active employee with type DOCTOR can create medication request!", [validation: :required]])
        {:invalid_person, _} ->
          Operation.call_changeset(operation, &add_error/4, [:"person_id",
            "Only active legal entity with type MSP can provide medication request!", [validation: :required]])
        {:invalid_division, _} ->
          Operation.call_changeset(operation, &add_error/4, [:"division_id",
            "Only employee of active divisions can create medication request!", [validation: :required]])
        {:invalid_state, {field, message}} -> Operation.call_changeset(operation, &add_error/4, [field, message, []])
        {:invalid_declarations_count, _} ->
          Operation.call_changeset(operation, &add_error/4, [:"employee_id",
            "Only doctors with an active declaration with the patient can create medication request!", []])
        {:invalid_medication, _} ->
          Operation.call_changeset(operation, &add_error/4, [:"medication_id",
              "Not found any medications allowed for create medication request for this medical program!", []])
        {:invalid_medication_qty, _} ->
          Operation.call_changeset(operation, &add_error/4, [:"medication_qty",
              "The amount of medications in medication request must be divisible to package minimum quantity", []])
      end
    %{operation| valid?: false}
  end
end
