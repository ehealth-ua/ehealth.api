defmodule Core.Contracts do
  @moduledoc false

  import Core.API.Helpers.Connection, only: [get_client_id: 1, get_consumer_id: 1]
  import Ecto.Changeset
  import Ecto.Query

  alias Core.ContractRequests
  alias Core.ContractRequests.ContractRequest
  alias Core.Contracts.Contract
  alias Core.Contracts.ContractDivision
  alias Core.Contracts.ContractEmployee
  alias Core.Contracts.ContractEmployeeSearch
  alias Core.Contracts.Search
  alias Core.Divisions
  alias Core.Divisions.Division
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.EventManager
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.PRMRepo
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Preload
  alias Core.Validators.Reference
  alias Core.Validators.Signature, as: SignatureValidator
  alias Scrivener.Page

  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]

  @status_verified Contract.status(:verified)
  @status_terminated Contract.status(:terminated)

  @fields_required ~w(
    id
    start_date
    end_date
    status
    contractor_legal_entity_id
    contractor_owner_id
    contractor_base
    contractor_payment_details
    contractor_rmsp_amount
    nhs_legal_entity_id
    nhs_signer_id
    nhs_payment_method
    nhs_signer_base
    issue_city
    nhs_contract_price
    contract_number
    contract_request_id
    is_suspended
    is_active
    inserted_by
    updated_by
    id_form
    nhs_signed_date
  )a

  @fields_optional ~w(
    parent_contract_id
    status_reason
    external_contractor_flag
    external_contractors
  )a

  def list(params, client_type, headers) do
    client_id = get_client_id(headers)

    with %Ecto.Changeset{valid?: true, changes: changes} <- Search.changeset(params),
         {:edrpou, {:ok, changes}} <- {:edrpou, validate_edrpou(changes)},
         {:ok, changes} <- validate_client_type(client_id, client_type, changes),
         %Page{entries: contracts} = paging <- search(changes),
         contracts <- PRMRepo.preload(contracts, :contract_divisions),
         {:ok, references} <- load_contracts_references(contracts) do
      {:ok, %{paging | entries: contracts}, references}
    else
      {:edrpou, _} ->
        get_empty_response(params)

      error ->
        error
    end
  end

  def create(%{parent_contract_id: parent_contract_id} = params, user_id) when not is_nil(parent_contract_id) do
    with %Contract{} = contract <- PRMRepo.get(Contract, parent_contract_id),
         :ok <- validate_contract_status(@status_verified, contract) do
      contract = load_references(contract)

      PRMRepo.transaction(fn ->
        ContractEmployee
        |> where([ce], ce.contract_id == ^contract.id)
        |> PRMRepo.update_all(set: [end_date: NaiveDateTime.utc_now(), updated_by: params.updated_by])

        with {:ok, _} <-
               contract
               |> changeset(%{"status" => @status_terminated})
               |> PRMRepo.update() do
          EventManager.insert_change_status(contract, @status_terminated, user_id)
        end

        with {:ok, new_contract} <- do_create(params) do
          new_contract
        end
      end)
    end
  end

  def create(params, _) do
    do_create(params)
  end

  defp do_create(params) do
    with {:ok, contract} <-
           %Contract{}
           |> changeset(params)
           |> PRMRepo.insert() do
      {:ok, load_references(contract)}
    end
  end

  def prolongate(id, params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with {:ok, contract} <- fetch_by_id(id),
         :ok <- validate_contract_status(@status_verified, contract),
         :ok <- JsonSchema.validate(:contract_prolongate, params),
         :ok <- validate_legal_entity_allowed(client_id, [contract.nhs_legal_entity_id]),
         :ok <- validate_contractor_related_legal_entity(contract.contractor_legal_entity_id),
         {:ok, contractor_legal_entity} <- LegalEntities.fetch_by_id(contract.contractor_legal_entity_id),
         :ok <- check_legal_entity_is_active(contractor_legal_entity, :contractor),
         :ok <- validate_end_date(params["end_date"], contract.end_date),
         {:ok, contract} <-
           contract
           |> changeset(%{
             "end_date" => params["end_date"],
             "updated_by" => user_id
           })
           |> PRMRepo.update() do
      load_contract_references(contract)
    end
  end

  def update(id, params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with %Contract{} = contract <- get_by_id(id),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         :ok <- JsonSchema.validate(:contract_sign, params),
         {:ok, %{"content" => content, "signer" => signer}} <- decode_signed_content(params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "contract_request_update"),
         :ok <- validate_status(contract, Contract.status(:verified)),
         :ok <- validate_update_json_schema(content),
         {:ok, _} <- process_employee_division(contract, content, user_id, client_id),
         :ok <-
           save_signed_content(
             contract.id,
             params,
             headers,
             content["employee_id"]
           ) do
      now = NaiveDateTime.utc_now()

      query =
        ContractEmployee
        |> where([ce], ce.contract_id == ^contract.id)
        |> where(
          [ce],
          ce.start_date <= ^now and (is_nil(ce.end_date) or ce.end_date >= ^now)
        )

      contract
      |> PRMRepo.preload([contract_employees: query], force: true)
      |> load_contract_references()
    end
  end

  def terminate(id, params, headers) do
    legal_entity_id = get_client_id(headers)
    user_id = get_consumer_id(headers)

    with {:ok, contract, references} <- fetch_by_id(id, params),
         :ok <- JsonSchema.validate(:contract_terminate, params),
         :ok <-
           validate_legal_entity_allowed(legal_entity_id, [
             contract.contractor_legal_entity_id,
             contract.nhs_legal_entity_id
           ]),
         :ok <- validate_status(contract, Contract.status(:verified)),
         {:ok, contract} <-
           contract
           |> changeset(%{
             "status_reason" => params["status_reason"],
             "status" => Contract.status(:terminated),
             "updated_by" => user_id
           })
           |> PRMRepo.update(),
         EventManager.insert_change_status(contract, contract.status, user_id) do
      {:ok, contract, references}
    end
  end

  defp validate_contract_status(status, %Contract{status: status}), do: :ok

  defp validate_contract_status(_, _) do
    {:error, {:conflict, "Incorrect contract status to modify it"}}
  end

  defp validate_legal_entity_allowed(client_id, allowed_ids) do
    if client_id in allowed_ids do
      :ok
    else
      {:error, {:forbidden, "Legal entity is not allowed to this action by client_id"}}
    end
  end

  defp validate_update_json_schema(%{"is_active" => false} = content) do
    JsonSchema.validate(:contract_update_employees_is_active, content)
  end

  defp validate_update_json_schema(content) do
    JsonSchema.validate(:contract_update_employees, content)
  end

  defp validate_legal_entity_division(%Contract{contractor_legal_entity_id: legal_entity_id}, %{"division_id" => id}) do
    with %Page{entries: [_]} <- Divisions.search(legal_entity_id, %{"ids" => id, "status" => Division.status(:active)}) do
      :ok
    else
      _ -> Error.dump("Division must be active and within current legal_entity")
    end
  end

  defp validate_legal_entity_employee(%Contract{contractor_legal_entity_id: legal_entity_id}, %{"employee_id" => id}) do
    with %Employee{} = employee <- Employees.get_by_id(id),
         true <- employee.legal_entity_id == legal_entity_id && employee.status == Employee.status(:approved) do
      :ok
    else
      _ -> Error.dump("Employee must be within current legal_entity")
    end
  end

  defp process_employee_division(
         %Contract{id: id} = contract,
         %{"employee_id" => employee_id, "division_id" => division_id} = params,
         user_id,
         client_id
       ) do
    case PRMRepo.get(Employee, employee_id) do
      nil ->
        Error.dump("Employee_id is invalid")

      %Employee{speciality: speciality, legal_entity_id: legal_entity_id} ->
        employee_speciality = Map.get(speciality, "speciality")

        with %ContractEmployee{} = contract_employee <- get_contract_employee(id, employee_id, division_id),
             :ok <- validate_employee_speciality_limit(Map.get(params, "declaration_limit"), employee_speciality),
             :ok <- check_employee_legal_entity(client_id, legal_entity_id) do
          update_contract_employee(contract, contract_employee, params, user_id)
        else
          nil ->
            insert_and_validate_contract_employee(
              contract,
              params,
              user_id,
              client_id,
              employee_speciality,
              legal_entity_id
            )

          error ->
            error
        end
    end
  end

  defp insert_and_validate_contract_employee(contract, params, user_id, client_id, employee_speciality, legal_entity_id) do
    with :ok <- validate_employee_speciality_limit(Map.get(params, "declaration_limit"), employee_speciality),
         :ok <- check_employee_legal_entity(client_id, legal_entity_id) do
      insert_contract_employee(contract, params, user_id)
    end
  end

  defp validate_employee_speciality_limit(_, nil), do: {:error, {:"422", "Employee speciality is invalid"}}
  defp validate_employee_speciality_limit(nil, _), do: :ok

  defp validate_employee_speciality_limit(declaration_limit, employee_speciality) do
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

  defp check_employee_legal_entity(client_id, client_id), do: :ok

  defp check_employee_legal_entity(_, _),
    do: Error.dump("Employee should be active Doctor within current legal_entity_id")

  defp update_contract_employee(_, %ContractEmployee{} = contract_employee, %{"is_active" => false}, user_id) do
    contract_employee
    |> ContractEmployee.changeset(%{"end_date" => NaiveDateTime.utc_now(), "updated_by" => user_id})
    |> PRMRepo.update()
  end

  defp update_contract_employee(%Contract{} = contract, %ContractEmployee{} = contract_employee, params, user_id) do
    with :ok <- validate_legal_entity_division(contract, params),
         :ok <- validate_legal_entity_employee(contract, params),
         :ok <- validate_employee_division(contract, params) do
      contract_employee
      |> ContractEmployee.changeset(%{"end_date" => NaiveDateTime.utc_now(), "updated_by" => user_id})
      |> PRMRepo.update()

      insert_contract_employee(contract, params, user_id)
    end
  end

  defp insert_contract_employee(_, %{"is_active" => false}, _), do: Error.dump("Invalid employee_id to deactivate")

  defp insert_contract_employee(%Contract{} = contract, params, user_id) do
    with :ok <- validate_employee_division(contract, params) do
      %ContractEmployee{contract: contract}
      |> ContractEmployee.changeset(%{
        employee_id: params["employee_id"],
        division_id: params["division_id"],
        staff_units: params["staff_units"],
        declaration_limit: params["declaration_limit"],
        start_date: NaiveDateTime.utc_now(),
        inserted_by: user_id,
        updated_by: user_id
      })
      |> PRMRepo.insert()
    end
  end

  defp validate_employee_division(%Contract{} = contract, params) do
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

  defp get_contract_employee(contract_id, employee_id, division_id) do
    ContractEmployee
    |> where([ce], ce.contract_id == ^contract_id)
    |> where([ce], ce.employee_id == ^employee_id)
    |> where([ce], ce.division_id == ^division_id)
    |> where([ce], is_nil(ce.end_date) or ce.end_date > ^NaiveDateTime.utc_now())
    |> PRMRepo.one()
  end

  def decode_signed_content(
        %{"signed_content" => signed_content, "signed_content_encoding" => encoding},
        headers
      ) do
    SignatureValidator.validate(signed_content, encoding, headers)
  end

  defp validate_status(%Contract{status: status}, status), do: :ok
  defp validate_status(_, _), do: {:error, {:conflict, "Not active contract can't be updated"}}

  def get_by_id(id) do
    Contract
    |> where([c], c.id == ^id)
    |> join(:left, [c], ce in ContractEmployee, c.id == ce.contract_id and is_nil(ce.end_date))
    |> join(:left, [c], cd in ContractDivision, c.id == cd.contract_id)
    |> preload([c, ce, cd], contract_employees: ce, contract_divisions: cd)
    |> PRMRepo.one()
  end

  def get_by_id(id, params) do
    with %Contract{} = contract <- get_by_id(id),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         {:ok, contract, references} <- load_contract_references(contract) do
      {:ok, contract, references}
    end
  end

  def fetch_by_id(id) do
    case get_by_id(id) do
      %Contract{} = contract -> {:ok, contract}
      _ -> {:error, {:not_found, "Contract not found"}}
    end
  end

  def fetch_by_id(id, params) do
    case get_by_id(id, params) do
      {:ok, _contract, _references} = result -> result
      _ -> {:error, {:not_found, "Contract not found"}}
    end
  end

  defp validate_contractor_related_legal_entity(contractor_legal_entity_id) do
    with %RelatedLegalEntity{} <-
           RelatedLegalEntity
           |> where([r], r.merged_from_id == ^contractor_legal_entity_id and r.is_active)
           |> limit(1)
           |> PRMRepo.one() do
      :ok
    else
      _ -> Error.dump("Contract for this legal entity must be resign with standard procedure")
    end
  end

  defp validate_end_date(end_date, contract_end_date) do
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

  def get_printout_content(id, client_type, headers) do
    with %Contract{contract_request_id: contract_request_id} = contract <- get_by_id(id),
         {:ok, %ContractRequest{} = contract_request, _} <-
           ContractRequests.get_by_id(headers, client_type, contract_request_id),
         {:ok, %{"printout_content" => printout_content}} <-
           ContractRequests.decode_and_validate_signed_content(contract_request, headers) do
      {:ok, contract, printout_content}
    end
  end

  def get_employees_by_id(id, params, headers) do
    client_id = get_client_id(headers)

    with %LegalEntity{} = client_legal_entity <- PRMRepo.get(LegalEntity, client_id),
         :ok <- check_legal_entity_is_active(client_legal_entity, :client),
         %Contract{} = contract <- PRMRepo.get(Contract, id),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         %Ecto.Changeset{valid?: true, changes: changes} <- ContractEmployeeSearch.changeset(params),
         %Page{entries: contract_employees} = paging <- contract_employee_search(contract, changes) do
      {:ok, paging, load_contract_employees_references(contract_employees)}
    end
  end

  defp check_legal_entity_is_active(%LegalEntity{is_active: true}, _), do: :ok
  defp check_legal_entity_is_active(_, :client), do: {:error, {:forbidden, "Client is not active"}}
  defp check_legal_entity_is_active(_, :contractor), do: {:error, {:conflict, "Contractor legal entity is not active"}}

  defp contract_employee_search(%Contract{id: contract_id}, search_params) do
    is_active = Map.get(search_params, :is_active)

    params =
      search_params
      |> Map.drop([:is_active, :page_size, :page])
      |> Map.to_list()

    query = if Enum.count(params) > 0, do: where(ContractEmployee, ^params), else: ContractEmployee

    query
    |> where([ce], ce.contract_id == ^contract_id)
    |> add_is_active_query_param(is_active)
    |> PRMRepo.paginate(Map.take(search_params, ~w(page page_size)a))
  end

  defp add_is_active_query_param(query, false) do
    where(query, [ce], not (is_nil(ce.end_date) or ce.end_date > ^NaiveDateTime.utc_now()))
  end

  defp add_is_active_query_param(query, _) do
    where(query, [ce], is_nil(ce.end_date) or ce.end_date > ^NaiveDateTime.utc_now())
  end

  defp load_contract_employees_references(contract_employees) do
    Preload.preload_references_for_list(contract_employees, [{:employee_id, :employee}])
  end

  defp search(changes) do
    date_from_start_date = Map.get(changes, :date_from_start_date)
    date_to_start_date = Map.get(changes, :date_to_start_date)
    date_from_end_date = Map.get(changes, :date_from_end_date)
    date_to_end_date = Map.get(changes, :date_to_end_date)
    legal_entity_id = Map.get(changes, :legal_entity_id)

    params = Map.drop(changes, ~w(
      date_from_start_date
      date_to_start_date
      date_from_end_date
      date_to_end_date
      legal_entity_id
      page
      page_size
    )a)

    query = if map_size(params) > 0, do: where(Contract, ^Map.to_list(params)), else: Contract

    query
    |> add_date_range_at_query(:start_date, date_from_start_date, date_to_start_date)
    |> add_date_range_at_query(:end_date, date_from_end_date, date_to_end_date)
    |> add_legal_entity_id_query(legal_entity_id)
    |> PRMRepo.paginate(Map.take(changes, ~w(page page_size)a))
  end

  defp add_date_range_at_query(query, _, nil, nil), do: query

  defp add_date_range_at_query(query, attr, date_from, nil) do
    where(query, [c], field(c, ^attr) >= ^date_from)
  end

  defp add_date_range_at_query(query, attr, nil, date_to) do
    where(query, [c], field(c, ^attr) <= ^date_to)
  end

  defp add_date_range_at_query(query, attr, date_from, date_to) do
    where(query, [c], fragment("? BETWEEN ? AND ?", field(c, ^attr), ^date_from, ^date_to))
  end

  defp add_legal_entity_id_query(query, nil), do: query

  defp add_legal_entity_id_query(query, legal_entity_id) do
    where(query, [c], c.nhs_legal_entity_id == ^legal_entity_id or c.contractor_legal_entity_id == ^legal_entity_id)
  end

  defp validate_contractor_legal_entity_id(%Contract{} = contract, %{
         "contractor_legal_entity_id" => contractor_legal_entity_id
       }) do
    if contract.contractor_legal_entity_id == contractor_legal_entity_id,
      do: :ok,
      else: {:error, {:forbidden, "You are not allowed to view this contract"}}
  end

  defp validate_contractor_legal_entity_id(_contract, _params), do: :ok

  def load_contract_references(contract) do
    references =
      Preload.preload_references(contract, [
        {:contractor_legal_entity_id, :legal_entity},
        {:contractor_owner_id, :employee},
        {:nhs_legal_entity_id, :legal_entity},
        {:nhs_signer_id, :employee},
        {:contract_request_id, :contract_request},
        {[:contract_employees, "$", :employee_id], :employee},
        {[:contract_divisions, "$", :division_id], :division},
        {[:external_contractors, "$", "divisions", "$", "id"], :division},
        {[:external_contractors, "$", "legal_entity_id"], :legal_entity}
      ])

    {:ok, contract, references}
  end

  defp changeset(%Search{} = contract, attrs) do
    fields =
      :fields
      |> Search.__schema__()
      |> List.delete(:ids)

    cast(contract, attrs, fields)
  end

  defp changeset(%Contract{} = contract, attrs) do
    inserted_by = Map.get(attrs, :inserted_by)
    updated_by = Map.get(attrs, :updated_by)

    attrs =
      case Map.get(attrs, :contractor_employee_divisions) do
        nil ->
          attrs

        contractor_employee_divisions ->
          contractor_employee_divisions =
            Enum.map(
              contractor_employee_divisions,
              &(&1
                |> Map.put("start_date", NaiveDateTime.from_erl!({Date.to_erl(attrs.start_date), {0, 0, 0}}))
                |> Map.put("inserted_by", inserted_by)
                |> Map.put("updated_by", updated_by))
            )

          Map.put(attrs, :contract_employees, contractor_employee_divisions)
      end

    attrs =
      case Map.get(attrs, :contractor_divisions) do
        nil ->
          attrs

        contractor_divisions ->
          contractor_divisions =
            Enum.map(
              contractor_divisions,
              &%{"division_id" => &1, "inserted_by" => inserted_by, "updated_by" => updated_by}
            )

          Map.put(attrs, :contract_divisions, contractor_divisions)
      end

    contract
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> cast_assoc(:contract_employees)
    |> cast_assoc(:contract_divisions)
    |> validate_required(@fields_required)
  end

  defp save_signed_content(id, %{"signed_content" => signed_content}, headers, employee_id) do
    datetime =
      DateTime.utc_now()
      |> DateTime.to_unix()

    signed_content
    |> @media_storage_api.store_signed_content(
      :contract_bucket,
      id,
      "employee_update/#{employee_id}/#{datetime}",
      headers
    )
    |> case do
      {:ok, _} -> :ok
      _error -> {:error, {:bad_gateway, "Failed to save signed content"}}
    end
  end

  def update_is_suspended(ids, is_suspended) when is_list(ids) and is_boolean(is_suspended) do
    query = where(Contract, [c], c.id in ^ids)

    case PRMRepo.update_all(query, set: [is_suspended: is_suspended]) do
      {suspended, _} -> {:ok, suspended}
      err -> err
    end
  end

  def gen_relevant_get_links(id) do
    with {:ok, %{"data" => %{"secret_url" => secret_url}}} <-
           @media_storage_api.create_signed_url("GET", get_bucket(), "signed_content/signed_content", id, []) do
      [%{"type" => "SIGNED_CONTENT", "url" => secret_url}]
    end
  end

  defp validate_edrpou(search_params) do
    edrpou = Map.get(search_params, :edrpou)
    contractor_legal_entity_id = Map.get(search_params, :contractor_legal_entity_id)
    search_params = Map.delete(search_params, :edrpou)

    with false <- is_nil(edrpou),
         %LegalEntity{} = legal_entity <- PRMRepo.get_by(LegalEntity, edrpou: edrpou) do
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

  defp validate_client_type(_, "NHS", search_params), do: {:ok, search_params}

  defp validate_client_type(client_id, "MSP", %{contractor_legal_entity_id: id} = search_params) do
    cond do
      id == client_id -> {:ok, search_params}
      is_nil(id) -> {:ok, Map.put(search_params, :contractor_legal_entity_id, client_id)}
      true -> get_empty_response(search_params)
    end
  end

  defp validate_client_type(_, nil, search_params), do: {:ok, search_params}

  defp load_contracts_references(contracts) do
    references =
      Preload.preload_references_for_list(contracts, [
        {:contractor_owner_id, :employee}
      ])

    {:ok, references}
  end

  defp get_empty_response(params) do
    {:ok,
     %Page{
       entries: [],
       page_number: 1,
       page_size: Map.get(params, "page_size", 50),
       total_entries: 0,
       total_pages: 1
     }, %{}}
  end

  defp load_references(%Contract{} = contract) do
    contract
    |> PRMRepo.preload(:contract_employees)
    |> PRMRepo.preload(:contract_divisions)
  end

  defp get_bucket do
    Confex.fetch_env!(:core, Core.API.MediaStorage)[:contract_bucket]
  end
end
