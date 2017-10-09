defmodule EHealth.MedicationRequestRequest.Operation do
  @moduledoc false
  @enforce_keys [:changeset]

  defstruct [:changeset, :proxy, :valid?]

  alias EHealth.MedicationRequestRequest.Operation

  def new(%Ecto.Changeset{} = changeset) do
    %Operation{changeset: changeset, proxy: %{}, valid?: true}
  end

  def changeset(%Operation{} = operation) do
    operation.changeset
  end

  def add_proxy(%Operation{} = operation, key, map) when is_map(map) or is_list(map) do
    Map.put(operation, :proxy, Map.put(operation.proxy, key, map))
  end

  def add_proxy(%Operation{} = operation, key, fun, args) when is_function(fun) when is_list(args) do
    Map.put(operation, :proxy, Map.put(operation.proxy, key, apply(fun, [operation] ++ args)))
  end

  def call_changeset(%Operation{} = operation, function, args) do
    {_, operation} =
      Map.get_and_update(
        operation,
        :changeset,
        fn changeset -> {:ok, apply(function, [changeset] ++ args)} end
      )
    operation
  end
end

defmodule EHealth.MedicationRequestRequest.DataMapper do
  @moduledoc false
  import Ecto.Changeset

  alias EHealth.PRM.Employees
  alias EHealth.PRM.LegalEntities
  alias EHealth.PRM.Divisions
  alias EHealth.MedicationRequestRequest.EmbeddedData
  alias EHealth.MedicationRequestRequest.Validations
  alias EHealth.Utils.Helpers
  alias EHealth.API.MPI
  alias EHealth.MedicationRequestRequest.Operation

  @map_fields [:created_at, :started_at, :ended_at, :dispense_valid_from, :employee_id,
               :dispense_valid_to, :person_id, :division_id, :medication_id, :medication_qty]

  def map_data(changeset, data, client_id) do
    operation =
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
    put_embed(changeset, :data, operation.changeset)
  end

  defp get_employee(data) do
    Helpers.get_assoc_by_func("employee_id", fn -> Employees.get_employee_by_id(data["employee_id"]) end)
  end

  defp validate_employee(_operation, employee) do
    Validations.validate_doctor(employee)
  end

  defp get_person(data) do
    Helpers.get_assoc_by_func("person_id", fn -> MPI.person(data["person_id"]) end)
  end

  defp get_legal_entity(client_id) do
    case LegalEntities.get_by_id_preload(client_id, :medical_service_provider) do
      nil -> {:error, "client_id"}
      le -> {:ok, le}
    end
  end

  defp put_legal_entity(operation, le) do
    operation =
      operation
      |> Operation.call_changeset(&Ecto.Changeset.put_change/3, [:legal_entity_id, le.id])
      |> Operation.add_proxy(:legal_entity, le)
    {:ok, operation}
  end

  defp validate_declaration_existance(operation, _data) do
    Validations.validate_declaration_existance(operation.proxy.employee, operation.proxy.person)
  end

  defp validate_medication_id(_operation, data) do
    Validations.validate_medication_id(data["medication_id"], data["medication_qty"])
  end

  defp validate_person(_operation, person) do
    Validations.validate_person(person)
  end

  defp get_division(data) do
    Helpers.get_assoc_by_func("division_id", fn -> Divisions.get_division_by_id(data["division_id"]) end)
  end

  def validate_division(operation, division) do
    Validations.validate_divison(division, operation.proxy.legal_entity.id)
  end

  defp validate_dates(_operation, data) do
    Validations.validate_dates(data)
  end

  defp validate_foreign_key(operation, data, fetch_function, validate_function, opts \\ [])
  defp validate_foreign_key(%Operation{valid?: false} = operation, _data, _fetch_function, _validate_function, _opts) do
    operation
  end
  defp validate_foreign_key(%Operation{valid?: true} = operation, data, fetch_function, validate_function, opts) do
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
          Operation.add_proxy(operation, opts[:key], entity)
        else
          operation
        end
      {:error, %Operation{} = operation} -> operation
      {error_name, error_obj} -> custom_errors({error_name, error_obj}, operation)
    end
  end

  defp fk_error(operation, field) do
    operation
    |> Operation.call_changeset(&add_error/4, [String.to_atom(field),
                                               "#{Helpers.from_filed_to_name(field)} not found",
                                               [validation: :required]])
    |> Map.replace(:valid?, false)
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
