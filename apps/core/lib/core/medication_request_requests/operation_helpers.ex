defmodule Core.MedicationRequestRequest.OperationHelpers do
  @moduledoc false

  import Ecto.Changeset

  alias Core.Divisions
  alias Core.Employees
  alias Core.LegalEntities
  alias Core.MedicalPrograms
  alias Core.MedicationRequestRequest.Operation
  alias Core.MedicationRequestRequest.Validations
  alias Core.Medications
  alias Core.Persons
  alias Core.Utils.Helpers

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def get_employee(id) do
    Helpers.get_assoc_by_func("employee_id", fn ->
      id
      |> Employees.get_by_id()
      |> @read_prm_repo.preload(:division)
    end)
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
    Helpers.get_assoc_by_func("person_id", fn ->
      with {:ok, person} <- Persons.get_by_id(id) do
        person
      end
    end)
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

  def validate_dispense_valid_from(operation, attrs) do
    Validations.validate_dispense_valid_from(operation, attrs)
  end

  def validate_dispense_valid_to(operation, attrs) do
    Validations.validate_dispense_valid_to(operation, attrs)
  end

  def validate_existing_medication_requests(_operation, data) do
    Validations.validate_existing_medication_requests(data, data["medical_program_id"])
  end

  def validate_dates(_operation, data) do
    Validations.validate_dates(data)
  end

  def validate_medical_event_entity(operation, context) do
    Validations.validate_medical_event_entity(context, operation.data.person["id"])
  end

  def validate_dosage_instruction(_operation, dosage_instruction) do
    Validations.validate_dosage_instruction(dosage_instruction)
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
      {:ok, %Operation{} = operation} ->
        operation

      {:ok, entity} ->
        if opts[:key] do
          Operation.add_data(operation, opts[:key], entity)
        else
          operation
        end

      {:error, %Operation{} = operation} ->
        operation

      {error_name, error_obj} ->
        custom_errors({error_name, error_obj}, operation)
    end
  end

  def fk_error(operation, field) do
    error = [String.to_atom(field), "#{Helpers.from_filed_to_name(field)} not found", [validation: :required]]

    operation
    |> Operation.call_changeset(&add_error/4, error)
    |> Map.put(:valid?, false)
  end

  def custom_errors(error_tuple, operation) when is_tuple(error_tuple) do
    error_tuple
    |> add_changeset_error(operation)
    |> Map.put(:valid?, false)
  end

  defp add_changeset_error({:invalid_employee, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :employee_id,
      "Only active employee with type DOCTOR can create medication request!",
      [validation: :required]
    ])
  end

  defp add_changeset_error({:invalid_person, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :person_id,
      "Only active legal entity with type MSP can provide medication request!",
      [validation: :required]
    ])
  end

  defp add_changeset_error({:invalid_division, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :division_id,
      "Only employee of active divisions can create medication request!",
      [validation: :required]
    ])
  end

  defp add_changeset_error({:invalid_state, {field, message}}, operation) do
    Operation.call_changeset(operation, &add_error/4, [field, message, []])
  end

  defp add_changeset_error({:invalid_declarations_count, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :employee_id,
      "Only doctors with an active declaration with the patient can create medication request!",
      []
    ])
  end

  defp add_changeset_error({:invalid_medication, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :medication_id,
      "Not found any medications allowed for create medication request for this medical program!",
      []
    ])
  end

  defp add_changeset_error({:invalid_medication_qty, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :medication_qty,
      "The amount of medications in medication request must be divisible to package minimum quantity",
      []
    ])
  end

  defp add_changeset_error({:invalid_encounter, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :context,
      "Entity in status \"entered-in-error\" can not be referenced",
      [validation: :invalid]
    ])
  end

  defp add_changeset_error({:not_found_encounter, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :context,
      "Entity not found",
      [validation: :invalid]
    ])
  end

  defp add_changeset_error({:sequence_error, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :dosage_instruction,
      "Sequence must be unique",
      [validation: :invalid]
    ])
  end

  defp add_changeset_error({:invalid_dosage_instruction, %{description: description, path: path}}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :dosage_instruction,
      "incorrect #{description} (#{path})",
      [validation: :invalid]
    ])
  end

  defp add_changeset_error({:invalid_period, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :ended_at,
      "Treatment period cannot be less than MR expiration period",
      [validation: :invalid]
    ])
  end

  defp add_changeset_error({:invalid_existing_medication_requests, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :created_at,
      "It's to early to create new medication request for such innm_dosage and medical_program_id",
      [validation: :invalid]
    ])
  end

  defp add_changeset_error({:invalid_signature, reason}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :signed_medication_request_request,
      reason,
      [validation: :invalid]
    ])
  end

  defp add_changeset_error({:invalid_started_at, _}, operation) do
    Operation.call_changeset(operation, &add_error/4, [
      :started_at,
      "It can be only 1 active/ completed medication request request or " <>
        "medication request per one innm for the same patient at the same period of time!",
      [validation: :invalid]
    ])
  end
end
