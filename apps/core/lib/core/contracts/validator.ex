defmodule Core.Contracts.Validator do
  @moduledoc false

  import Ecto.Query

  alias Core.Contracts
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias Core.Dictionaries.Dictionary
  alias Core.Divisions
  alias Core.Divisions.Division
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Reference
  alias Scrivener.Page

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def validate_contractor_related_legal_entity(contractor_legal_entity_id) do
    with %RelatedLegalEntity{} <-
           RelatedLegalEntity
           |> where([r], r.merged_from_id == ^contractor_legal_entity_id and r.is_active)
           |> limit(1)
           |> @read_prm_repo.one() do
      :ok
    else
      _ -> {:error, {:conflict, "Contract for this legal entity must be resign with standard procedure"}}
    end
  end

  def validate_end_date(end_date, contract_end_date) do
    end_date = Date.from_iso8601!(end_date)

    with {:now, :gt} <- {:now, Date.compare(end_date, Date.utc_today())},
         {:contract_end_date, :gt} <- {:contract_end_date, Date.compare(end_date, contract_end_date)} do
      :ok
    else
      {:now, _} ->
        Error.dump(%ValidationError{
          description: "End date should be greater then now",
          path: "$.end_date"
        })

      {:contract_end_date, _} ->
        Error.dump(%ValidationError{
          description: "End date should be greater then contract end date",
          path: "$.end_date"
        })
    end
  end

  def validate_date_activeness(%Date{} = end_date, %Date{} = compared_date \\ Date.utc_today()) do
    case Date.compare(end_date, compared_date) do
      :gt -> :ok
      _ -> {:error, {:conflict, "Contract dates are not valid"}}
    end
  end

  def validate_status_reason(status_reason, %Dictionary{values: values}) do
    values
    |> Map.keys()
    |> Enum.reject(&String.starts_with?(&1, "AUTO_"))
    |> Enum.member?(status_reason)
    |> case do
      true -> :ok
      _ -> Error.dump(%ValidationError{description: "Status reason is not allowed", path: "$.status_reason"})
    end
  end

  def validate_contractor_legal_entity_id(%{contractor_legal_entity_id: contractor_legal_entity_id}, %{
        "contractor_legal_entity_id" => param_contractor_legal_entity_id
      }) do
    if contractor_legal_entity_id == param_contractor_legal_entity_id,
      do: :ok,
      else: {:error, {:forbidden, "You are not allowed to view this contract"}}
  end

  def validate_contractor_legal_entity_id(_contract, _params), do: :ok

  def validate_edrpou(search_params) do
    edrpou = Map.get(search_params, :edrpou)
    contractor_legal_entity_id = Map.get(search_params, :contractor_legal_entity_id)
    search_params = Map.delete(search_params, :edrpou)

    with false <- is_nil(edrpou),
         %LegalEntity{} = legal_entity <- @read_prm_repo.get_by(LegalEntity, edrpou: edrpou) do
      cond do
        contractor_legal_entity_id == legal_entity.id ->
          {:ok, search_params}

        is_nil(contractor_legal_entity_id) ->
          search_params = Map.put(search_params, :contractor_legal_entity_id, legal_entity.id)
          {:ok, search_params}

        true ->
          :error
      end
    else
      true -> {:ok, search_params}
      nil -> :error
    end
  end

  def validate_client_type(_, "NHS", search_params), do: {:ok, search_params}

  def validate_client_type(client_id, type, %{contractor_legal_entity_id: id} = search_params)
      when type in ["MSP", "PHARMACY", "MSP_PHARMACY"] do
    cond do
      id == client_id -> {:ok, search_params}
      is_nil(id) -> {:ok, Map.put(search_params, :contractor_legal_entity_id, client_id)}
      true -> Contracts.get_empty_response(search_params)
    end
  end

  def validate_client_type(_, nil, search_params), do: {:ok, search_params}

  def validate_legal_entity_allowed(client_id, allowed_ids) do
    if client_id in allowed_ids do
      :ok
    else
      {:error, {:forbidden, "Legal entity is not allowed to this action by client_id"}}
    end
  end

  def validate_update_json_schema(%{"is_active" => false} = content) do
    JsonSchema.validate(:contract_update_employees_is_active, content)
  end

  def validate_update_json_schema(content) do
    JsonSchema.validate(:contract_update_employees, content)
  end

  def validate_legal_entity_division(%{contractor_legal_entity_id: legal_entity_id}, %{
        "division_id" => id
      }) do
    with %Page{entries: [_]} <- Divisions.search(legal_entity_id, %{"ids" => id, "status" => Division.status(:active)}) do
      :ok
    else
      _ -> Error.dump("Division must be active and within current legal_entity")
    end
  end

  def validate_legal_entity_employee(%{contractor_legal_entity_id: legal_entity_id}, %{
        "employee_id" => id
      }) do
    with %Employee{} = employee <- Employees.get_by_id(id),
         true <- employee.legal_entity_id == legal_entity_id && employee.status == Employee.status(:approved) do
      :ok
    else
      _ -> Error.dump("Employee must be within current legal_entity")
    end
  end

  def validate_employee_division(%CapitationContract{} = contract, params) do
    contract_divisions = Enum.map(contract.contract_divisions, &Map.get(&1, :division_id))

    with {:ok, %Employee{} = employee} <-
           Reference.validate(
             :employee,
             params["employee_id"],
             "$.employee_id"
           ),
         :ok <- check_employee(employee),
         :ok <- check_division_subset(params["division_id"], contract_divisions) do
      :ok
    end
  end

  defp check_division_subset(division_id, contract_divisions) do
    if division_id in contract_divisions do
      :ok
    else
      Error.dump(%ValidationError{description: "Division should be among contract_divisions", path: "$.division_id"})
    end
  end

  defp check_employee(%Employee{employee_type: "DOCTOR", status: "APPROVED"}), do: :ok

  defp check_employee(_) do
    Error.dump(%ValidationError{description: "Employee must be active DOCTOR", path: "$.employee.id"})
  end

  def validate_employee_speciality_limit(_, nil), do: {:error, {:"422", "Employee speciality is invalid"}}
  def validate_employee_speciality_limit(nil, _), do: :ok

  def validate_employee_speciality_limit(declaration_limit, employee_speciality) do
    config = Confex.fetch_env!(:core, :employee_speciality_limits)

    employee_speciality_limit =
      case employee_speciality do
        "THERAPIST" ->
          config[:therapist_declaration_limit]

        "PEDIATRICIAN" ->
          config[:pediatrician_declaration_limit]

        "FAMILY_DOCTOR" ->
          config[:family_doctor_declaration_limit]
      end

    if declaration_limit <= employee_speciality_limit do
      :ok
    else
      Error.dump("declaration_limit is not allowed for employee speciality")
    end
  end

  def validate_employee_legal_entity(client_id, client_id), do: :ok

  def validate_employee_legal_entity(_, _),
    do: Error.dump("Employee should be active Doctor within current legal_entity_id")

  def validate_contract_status(status, %{status: status}), do: :ok

  def validate_contract_status(_, _) do
    {:error, {:conflict, "Incorrect contract status to modify it"}}
  end

  def validate_status(%CapitationContract{status: status}, status), do: :ok
  def validate_status(%ReimbursementContract{status: status}, status), do: :ok
  def validate_status(%LegalEntity{status: status}, status), do: :ok
  def validate_status(%CapitationContract{}, _), do: {:error, {:conflict, "Not active contract can't be updated"}}
  def validate_status(%ReimbursementContract{}, _), do: {:error, {:conflict, "Not active contract can't be updated"}}
  def validate_status(%LegalEntity{}, _), do: {:error, {:conflict, "Contractor legal entity is not active"}}

  def validate_legal_entity_is_active(%LegalEntity{is_active: true}, _), do: :ok
  def validate_legal_entity_is_active(_, :client), do: {:error, {:forbidden, "Client is not active"}}
end
