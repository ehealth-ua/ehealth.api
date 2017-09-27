defmodule EHealth.MedicationDispense.API do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_client_id: 1, get_consumer_id: 1]
  import Ecto.Changeset, only: [cast: 3]
  alias EHealth.PRM.Divisions
  alias EHealth.PRM.Employees
  alias EHealth.PRM.LegalEntities
  alias EHealth.PRM.MedicalPrograms
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.PRM.Divisions.Schema, as: Division
  alias EHealth.PRM.Medications.Medication.Schema, as: Medication
  alias EHealth.API.OPS
  alias EHealth.MedicationDispenses.Search
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.Reference

  @search_fields ~w(
    id
    medication_request_id
    legal_entity_id
    division_id
    status
    page
    page_size
  )a

  def list(params, headers) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- changeset(%Search{}, params),
         params <- Map.put(changes, "is_active", true),
         {:ok, %{"data" => medication_dispenses}} <- OPS.get_medication_dispenses(params, headers)
    do
      {:ok, medication_dispenses, get_references(medication_dispenses)}
    end
  end

  def get_by_id(params, headers) do
    legal_entity_id = Map.get(params, "legal_entity_id")
    search_params = Map.delete(params, "legal_entity_id")
    with {:ok, %{"data" => [medication_dispense]}} <- OPS.get_medication_dispenses(search_params, headers),
         {:ok, legal_entity} <- Reference.validate(:legal_entity, medication_dispense["legal_entity_id"]),
         :ok <- validate_legal_entity_id(medication_dispense, legal_entity_id),
         employee <- Employees.get_employee_by_id(medication_dispense["employee_id"]),
         division <- Divisions.get_division_by_id(medication_dispense["division_id"]),
         medical_program <- MedicalPrograms.get_by_id(medication_dispense["medical_program_id"])
    do
      {:ok, medication_dispense, %{
        employee: employee,
        legal_entity: legal_entity,
        division: division,
        medication_request: Map.get(medication_dispense, "medication_request"),
        medical_program: medical_program,
      }}
    else
      _ -> nil
    end
  end

  def create(headers, code, params) do
    legal_entity_id = get_client_id(headers)
    with :ok                       <- JsonSchema.validate(:medication_dispense, params),
         {:ok, legal_entity}       <- Reference.validate(:legal_entity, legal_entity_id),
         :ok                       <- validate_legal_entity(legal_entity),
         {:ok, medication_request} <- validate_medication_request(params["medication_request_id"]),
         {:ok, employee}           <- validate_employee(params["employee_id"], legal_entity_id),
         {:ok, division}           <- validate_division(params["division_id"], legal_entity_id),
         {:ok, medical_program}    <- validate_medical_program(params["medical_program_id"], medication_request),
         {:ok, dispense_details, medications} <- validate_medications(params["dispense_details"], medication_request),
         :ok                       <- validate_code(code, medication_request),
         :ok                       <- check_other_medication_dispenses(medication_request, headers),
         true                      <- check_medication_qty(params, medication_request),
         :ok                       <- check_medication_multiplicity(dispense_details, medications),
         params                    <- Map.put(params, "dispense_details", dispense_details),
         {:ok, %{"data" => medication_dispense}} <- OPS.create_medication_dispense(params)
    do
      {:ok, medication_dispense, %{
        employee: employee,
        legal_entity: legal_entity,
        division: division,
        medication_request: medication_request,
        medical_program: medical_program,
      }}
    end
  end

  def process(%{"id" => id} = params, headers) do
    attrs =
      params
      |> Map.take(~w(payment_id))
      |> Map.put("status", "PROCESSED")
      |> Map.put("updated_by", get_consumer_id(headers))
    with {:ok, medication_dispense, references} <- get_by_id(params, headers),
         :ok <- validate_status_transition(medication_dispense, "PROCESSED"),
         {:ok, %{"data" => medication_dispense}} <- OPS.update_medication_dispense(id,
           %{"medication_dispense" => attrs}, headers)
    do
      {:ok, medication_dispense, references}
    end
  end

  def reject(%{"id" => id} = params, headers) do
    attrs =
      params
      |> Map.take(~w(payment_id))
      |> Map.put("status", "REJECTED")
      |> Map.put("updated_by", get_consumer_id(headers))
    with {:ok, medication_dispense, references} <- get_by_id(params, headers),
         :ok <- validate_status_transition(medication_dispense, "REJECTED"),
         {:ok, %{"data" => medication_dispense}} <- OPS.update_medication_dispense(id,
           %{"medication_dispense" => attrs}, headers)
      do
      {:ok, medication_dispense, references}
    end
  end

  defp validate_legal_entity(%LegalEntity{is_active: is_active, status: status}) do
    if is_active && status == LegalEntity.status(:active) do
      :ok
    else
      {:conflict, "Legal entity is not active"}
    end
  end

  defp validate_medication_request(id) do
    with {:ok, medication_request} <- Reference.validate(:medication_request, id),
         :ok <- is_active_medication_request(medication_request),
         :ok <- validate_medication_request_period(medication_request)
    do
      {:ok, medication_request}
    end
  end

  defp validate_employee(id, legal_entity_id) do
    with {:ok, employee} <- Reference.validate(:employee, id),
         true <- is_active_employee(employee) && employee.legal_entity_id == legal_entity_id
    do
      {:ok, employee}
    else
      false -> {:conflict, "Employee is not active"}
      err -> err
    end
  end

  defp validate_division(id, legal_entity_id) do
    with {:ok, division} <- Reference.validate(:division, id),
         true <- is_active_division(division) && division.legal_entity_id == legal_entity_id
    do
      {:ok, division}
    else
      false -> {:conflict, "Division is not active"}
      err -> err
    end
  end

  defp validate_medical_program(id, medication_request) do
    is_active = fn medical_program ->
      medical_program.is_active && (medical_program.id == Map.get(medication_request, "medical_program_id"))
    end
    with {:ok, medical_program} <- Reference.validate(:medical_program, id),
         true <- is_active.(medical_program)
    do
      {:ok, medical_program}
    else
      false -> {:conflict, "Medical program is not active"}
      err -> err
    end
  end

  # TODO: not fully implemented
  defp validate_medications(dispense_details, medication_request) do
    result =
      dispense_details
      |> Enum.with_index
      |> Enum.map(fn {%{"medication_id" => id} = item, i} ->
        with {:ok, medication} <- Reference.validate(:medication, id, "$.dispense_details[#{i}].medication_id"),
            :ok <- validate_active_medication(medication, medication_request, i)
        # medication_request.medication_id exists in program_medications (is_active = true)
        do
          {:ok, Map.put(item, "reimbursement_amount", 15), medication}
        end
      end)
    errors = Enum.reduce(result, [], fn
      {:error, [err]}, acc -> [err | acc]
      _, acc -> acc
    end)
    details = Enum.reduce(result, [], fn
      {:ok, dispense_details, _}, acc -> [dispense_details | acc]
      _, acc -> acc
    end)
    medications =
      result
      |> Enum.map(fn
        {:ok, _, medication} -> medication
        _ -> nil
      end)
      |> Enum.filter(&(Kernel.!(is_nil(&1))))
    if Enum.empty?(errors), do: {:ok, details, medications}, else: {:error, errors}
  end

  defp validate_active_medication(%Medication{} = medication, %{"medication_id" => medication_id}, i) do
    ingredient = Enum.find(medication.ingredients, &(Map.get(&1, :is_primary)))
    is_valid_ingredient = Map.get(ingredient, :id) == medication_id
    if medication.is_active && is_valid_ingredient do
      :ok
    else
      {:error, [{
        %{description: "medication is not active",
          params: [],
          rule: :required
        }, "$.dispense_details[#{i}].medication_id"}]}
    end
  end

  defp validate_code(code, _) when is_nil(code) or code == "" do
    {:error, [{%{
                 rule: "required",
                 params: [],
                 description: "Missing or Invalid code"
              }, "$.code"}], :query_parameter}
  end
  defp validate_code(code, medication_request) do
    if code == Map.get(medication_request, "verification_code") do
      :ok
    else
      {:error, {:access_denied, "Incorrect code"}}
    end
  end

  defp check_other_medication_dispenses(%{"id" => medication_request_id}, headers) do
    params = %{"status" => "NEW,PROCESSED", "medication_request_id" => medication_request_id}
    with {:ok, %{"data" => []}} <- OPS.get_medication_dispenses(params, headers) do
      :ok
    else
      _ -> {:error, {:forbidden, "Active medication dispense already exists"}}
    end
  end

  defp check_medication_qty(%{"dispense_details" => details}, medication_request) do
    request_qty = Enum.reduce(details, 0, fn item, acc ->
      acc + Map.get(item, "medication_qty")
    end)
    request_qty <= Map.get(medication_request, "medication_qty")
  end

  defp is_active_medication_request(medication_request) do
    now = Date.utc_today()
    started_at = Date.from_iso8601!(Map.get(medication_request, "started_at"))
    ended_at = Date.from_iso8601!(Map.get(medication_request, "ended_at"))
    is_active = Map.get(medication_request, "is_active")
    status = Map.get(medication_request, "status")
    is_valid_period = Date.compare(started_at, now) != :gt && Date.compare(ended_at, now) != :lt

    if is_active and status == "SIGNED" && is_valid_period do
      :ok
    else
      {:conflict, "Medication request is not active"}
    end
  end

  defp is_active_employee(employee) do
    employee.is_active && employee.status == Employee.status(:approved)
  end

  defp is_active_division(division) do
    division.is_active && division.status == Division.status(:active)
  end

  defp validate_medication_request_period(medication_request) do
    from =
      medication_request
      |> Map.get("dispense_valid_from")
      |> Date.from_iso8601!()
    to =
      medication_request
      |> Map.get("dispense_valid_to")
      |> Date.from_iso8601!()
    now = Date.utc_today()

    if Date.compare(from, now) != :gt && Date.compare(to, now) != :lt do
      :ok
    else
      {:conflict, "Invalid dispense period"}
    end
  end

  defp changeset(%Search{} = search, attrs) do
    cast(search, attrs, @search_fields)
  end

  defp get_references(medication_dispenses) do
    reference_ids = %{
      division_ids: [],
      legal_entity_ids: [],
      employee_ids: [],
      medical_program_ids: [],
    }
    reference_ids = Enum.reduce(medication_dispenses, reference_ids, fn medication_dispense, acc ->
      %{acc |
        division_ids: [medication_dispense["division_id"] | acc.division_ids],
        legal_entity_ids: [medication_dispense["legal_entity_id"] | acc.legal_entity_ids],
        employee_ids: [medication_dispense["employee_id"] | acc.employee_ids],
        medical_program_ids: [medication_dispense["medical_program_id"] | acc.medical_program_ids],
      }
    end)
    divisions =
      reference_ids.division_ids
      |> Divisions.get_by_ids()
      |> Enum.into(%{}, &({Map.get(&1, :id), &1}))
    legal_entities =
      reference_ids.legal_entity_ids
      |> LegalEntities.get_by_ids()
      |> Enum.into(%{}, &({Map.get(&1, :id), &1}))
    employees =
      reference_ids.employee_ids
      |> Employees.get_by_ids()
      |> Enum.into(%{}, &({Map.get(&1, :id), &1}))
    medical_programs =
      reference_ids.medical_program_ids
      |> MedicalPrograms.get_by_ids()
      |> Enum.into(%{}, &({Map.get(&1, :id), &1}))
    %{
      divisions: divisions,
      legal_entities: legal_entities,
      employees: employees,
      medical_programs: medical_programs,
    }
  end

  defp validate_legal_entity_id(_, nil), do: :ok
  defp validate_legal_entity_id(medication_dispense, legal_entity_id) do
    if medication_dispense["legal_entity_id"] == legal_entity_id, do: :ok, else: {:error, :forbidden}
  end

  defp validate_status_transition(%{"status" => from_status}, to_status) do
    transitions = [
      {"NEW", "PROCESSED"},
      {"NEW", "REJECTED"},
      {"NEW", "EXPIRED"}
    ]

    is_valid_transition = Enum.find(transitions, fn {from, to} ->
      from == from_status && to == to_status
    end)

    if is_valid_transition do
      :ok
    else
      {:conflict, "Can't update medication dispense status from #{from_status} to #{to_status}"}
    end
  end

  defp check_medication_multiplicity(dispense_details, medications) do
    errors =
      dispense_details
      |> Enum.with_index
      |> Enum.map(fn {request_medication, i} ->
        medication = Enum.find(medications, &(Map.get(&1, :id) == request_medication["medication_id"]))
        if rem(medication.package_min_qty, request_medication["medication_qty"]) do
          :ok
        else
          {:error, [{
            %{description: "Requested medication brand quantity must be a multiplier of package minimal quantity",
            params: [],
            rule: :required
          }, "$.dispense_details[#{i}].medication_qty"}]}
        end
      end)
      |> Enum.filter(&(&1 != :ok))
    if Enum.empty?(errors) do
      :ok
    else
      {:error, errors
                |> Enum.map(&(elem(&1, 1)))
                |> Enum.concat}
    end
  end
end
