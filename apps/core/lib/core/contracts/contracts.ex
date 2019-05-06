defmodule Core.Contracts do
  @moduledoc false

  import Core.API.Helpers.Connection, only: [get_client_id: 1, get_consumer_id: 1]
  import Core.Contracts.Storage, only: [save_signed_content: 4]
  import Core.Contracts.Validator
  import Ecto.Changeset
  import Ecto.Query

  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.ContractRequests.RequestPack
  alias Core.ContractRequests.Storage
  alias Core.ContractRequests.Validator, as: ContractRequestsValidator
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ContractDivision
  alias Core.Contracts.ContractEmployee
  alias Core.Contracts.ContractEmployeeSearch
  alias Core.Contracts.ReimbursementContract
  alias Core.Contracts.Search
  alias Core.Dictionaries
  alias Core.Employees.Employee
  alias Core.EventManager
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Preload
  alias Core.Validators.Signature, as: SignatureValidator
  alias Scrivener.Page

  @status_verified CapitationContract.status(:verified)
  @status_terminated CapitationContract.status(:terminated)

  @capitation CapitationContract.type()
  @reimbursement ReimbursementContract.type()

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list(params, client_type, headers) do
    client_id = get_client_id(headers)

    with %Ecto.Changeset{valid?: true, changes: changes} <- Search.changeset(params),
         {:edrpou, {:ok, changes}} <- {:edrpou, validate_edrpou(changes)},
         {:ok, changes} <- validate_client_type(client_id, client_type, changes),
         %Page{entries: contracts} = paging <- search(changes),
         contracts <- @read_prm_repo.preload(contracts, :contract_divisions),
         {:ok, references} <- load_contracts_references(contracts) do
      {:ok, %{paging | entries: contracts}, references}
    else
      {:edrpou, _} ->
        get_empty_response(params)

      error ->
        error
    end
  end

  def create_from_contract_request(
        %RequestPack{contract_request: %{parent_contract_id: parent_contract_id}} = pack,
        user_id
      )
      when not is_nil(parent_contract_id) do
    schema = get_contract_schema_relatively_contract_request(pack.schema)

    with {:contract, %{__struct__: _} = contract} <- {:contract, @read_prm_repo.get(schema, parent_contract_id)},
         :ok <- validate_contract_status(@status_verified, contract) do
      contract = load_references(contract)
      params = get_contract_create_params(pack.contract_request)

      PRMRepo.transaction(fn ->
        if %CapitationContract{} == schema do
          ContractEmployee
          |> where([ce], ce.contract_id == ^contract.id)
          |> PRMRepo.update_all(set: [end_date: DateTime.utc_now(), updated_by: params.updated_by])
        end

        with {:ok, _} <-
               contract
               |> changeset(%{"status" => @status_terminated})
               |> PRMRepo.update() do
          EventManager.publish_change_status(contract, @status_terminated, user_id)
        end

        with {:ok, new_contract} <- do_create(schema, params) do
          new_contract
        else
          err -> PRMRepo.rollback(err)
        end
      end)
    else
      {:contract, nil} -> {:error, {:not_found, "Contract not found"}}
      err -> err
    end
  end

  def create_from_contract_request(pack, _) do
    pack.schema
    |> get_contract_schema_relatively_contract_request()
    |> do_create(get_contract_create_params(pack.contract_request))
  end

  defp do_create(schema, params) when schema in [CapitationContract, ReimbursementContract] do
    with {:ok, contract} <-
           schema
           |> struct(%{})
           |> schema.changeset(params)
           |> PRMRepo.insert() do
      {:ok, load_references(contract)}
    end
  end

  defp get_contract_create_params(%{__struct__: _, id: id, contract_id: contract_id} = contract_request) do
    contract_request
    |> Map.take(contract_request.__struct__.__schema__(:fields))
    |> Map.drop(~w(id inserted_at updated_at)a)
    |> Map.merge(%{
      id: contract_id,
      contract_request_id: id,
      is_suspended: false,
      is_active: true,
      status: CapitationContract.status(:verified)
    })
  end

  # ToDo: ugly schema matching. Is it possible match in more elegant way?
  defp get_contract_schema_relatively_contract_request(CapitationContractRequest), do: CapitationContract
  defp get_contract_schema_relatively_contract_request(ReimbursementContractRequest), do: ReimbursementContract

  def prolongate(id, params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with {:ok, contract} <- fetch_by_id(id, @capitation),
         :ok <- validate_contract_status(@status_verified, contract),
         :ok <- JsonSchema.validate(:contract_prolongate, params),
         :ok <- validate_legal_entity_allowed(client_id, [contract.nhs_legal_entity_id]),
         :ok <- validate_contractor_related_legal_entity(contract.contractor_legal_entity_id),
         {:ok, contractor_legal_entity} <- LegalEntities.fetch_by_id(contract.contractor_legal_entity_id),
         :ok <- validate_status(contractor_legal_entity, LegalEntity.status(:active)),
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

    with %CapitationContract{} = contract <- get_by_id(id, @capitation),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         :ok <- JsonSchema.validate(:contract_sign, params),
         {:ok, %{"content" => content, "signers" => [signer]}} <- decode_signed_content(params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "contract_request_update"),
         :ok <- validate_status(contract, CapitationContract.status(:verified)),
         :ok <- validate_update_json_schema(content),
         {:ok, _} <- process_employee_division(contract, content, user_id, client_id),
         :ok <-
           save_signed_content(
             contract.id,
             params,
             headers,
             content["employee_id"]
           ) do
      now = DateTime.utc_now()

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

  def terminate(id, %{"type" => type} = params, headers) do
    legal_entity_id = get_client_id(headers)
    user_id = get_consumer_id(headers)

    with {:ok, contract} <- fetch_by_id(id, type),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         :ok <- JsonSchema.validate(:contract_terminate, params),
         :ok <-
           validate_legal_entity_allowed(legal_entity_id, [
             contract.contractor_legal_entity_id,
             contract.nhs_legal_entity_id
           ]),
         :ok <- validate_status(contract, CapitationContract.status(:verified)),
         {:ok, contract} <- do_terminate(user_id, contract, params) do
      {:ok, contract}
    end
  end

  def do_terminate(user_id, contract, params) do
    update_result =
      contract
      |> changeset(%{
        "status_reason" => params["status_reason"],
        "reason" => params["reason"],
        "status" => CapitationContract.status(:terminated),
        "updated_by" => user_id,
        "end_date" => Date.utc_today() |> Date.to_iso8601()
      })
      |> PRMRepo.update()

    with {:ok, contract} <- update_result do
      EventManager.publish_change_status(contract, contract.status, user_id)
      update_result
    end
  end

  def suspend(%{__struct__: _} = contract, %{} = params, user_id) do
    params = Map.merge(params, %{updated_by: user_id})

    with {:ok, dictionary} <- Dictionaries.fetch_or_fail("CONTRACT_STATUS_REASON"),
         {_, true} <- {:status, contract.status == @status_verified},
         {_, true} <- {:is_suspended, contract.is_suspended == false},
         :ok <- validate_date_activeness(contract.end_date),
         :ok <- validate_status_reason(params.status_reason, dictionary),
         {:ok, updated_contract} <- contract |> changeset(params) |> PRMRepo.update() do
      EventManager.publish_change_status(updated_contract, user_id)
      {:ok, updated_contract}
    else
      {:status, _} -> {:error, {:conflict, "Incorrect status of contract to modify it"}}
      {:is_suspended, _} -> {:error, {:conflict, "Contract is suspended"}}
      err -> err
    end
  end

  defp process_employee_division(
         %CapitationContract{id: id} = contract,
         %{"employee_id" => employee_id, "division_id" => division_id} = params,
         user_id,
         client_id
       ) do
    case @read_prm_repo.get(Employee, employee_id) do
      nil ->
        Error.dump("Employee_id is invalid")

      %Employee{speciality: speciality, legal_entity_id: legal_entity_id} ->
        employee_speciality = Map.get(speciality, "speciality")

        with %ContractEmployee{} = contract_employee <- get_contract_employee(id, employee_id, division_id),
             :ok <- validate_employee_speciality_limit(Map.get(params, "declaration_limit"), employee_speciality),
             :ok <- validate_employee_legal_entity(client_id, legal_entity_id) do
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
         :ok <- validate_employee_legal_entity(client_id, legal_entity_id) do
      insert_contract_employee(contract, params, user_id)
    end
  end

  defp update_contract_employee(_, %ContractEmployee{} = contract_employee, %{"is_active" => false}, user_id) do
    contract_employee
    |> ContractEmployee.changeset(%{"end_date" => DateTime.utc_now(), "updated_by" => user_id})
    |> PRMRepo.update()
  end

  defp update_contract_employee(
         %CapitationContract{} = contract,
         %ContractEmployee{} = contract_employee,
         params,
         user_id
       ) do
    with :ok <- validate_legal_entity_division(contract, params),
         :ok <- validate_legal_entity_employee(contract, params),
         :ok <- validate_employee_division(contract, params) do
      contract_employee
      |> ContractEmployee.changeset(%{"end_date" => DateTime.utc_now(), "updated_by" => user_id})
      |> PRMRepo.update()

      insert_contract_employee(contract, params, user_id)
    end
  end

  defp insert_contract_employee(_, %{"is_active" => false}, _), do: Error.dump("Invalid employee_id to deactivate")

  defp insert_contract_employee(%CapitationContract{} = contract, params, user_id) do
    with :ok <- validate_employee_division(contract, params) do
      %ContractEmployee{contract: contract}
      |> ContractEmployee.changeset(%{
        employee_id: params["employee_id"],
        division_id: params["division_id"],
        staff_units: params["staff_units"],
        declaration_limit: params["declaration_limit"],
        start_date: DateTime.utc_now(),
        inserted_by: user_id,
        updated_by: user_id
      })
      |> PRMRepo.insert()
    end
  end

  defp get_contract_employee(contract_id, employee_id, division_id) do
    ContractEmployee
    |> where([ce], ce.contract_id == ^contract_id)
    |> where([ce], ce.employee_id == ^employee_id)
    |> where([ce], ce.division_id == ^division_id)
    |> where([ce], is_nil(ce.end_date) or ce.end_date > ^DateTime.utc_now())
    |> @read_prm_repo.one()
  end

  def decode_signed_content(
        %{"signed_content" => signed_content, "signed_content_encoding" => encoding},
        headers
      ) do
    SignatureValidator.validate(signed_content, encoding, headers)
  end

  def get_by_id(id, @capitation) do
    CapitationContract
    |> where([c], c.id == ^id and c.type == @capitation)
    |> join(:left, [c], ce in ContractEmployee, on: c.id == ce.contract_id and is_nil(ce.end_date))
    |> join(:left, [c], cd in ContractDivision, on: c.id == cd.contract_id)
    |> preload([c, ce, cd], contract_employees: ce, contract_divisions: cd)
    |> @read_prm_repo.one()
  end

  def get_by_id(id, @reimbursement) do
    ReimbursementContract
    |> where([c], c.id == ^id and c.type == @reimbursement)
    |> join(:left, [c], cd in ContractDivision, on: c.id == cd.contract_id)
    |> preload([c, cd], contract_divisions: cd)
    |> @read_prm_repo.one()
  end

  def fetch_by_id(id, type) when is_binary(type) do
    case get_by_id(id, type) do
      %{} = contract -> {:ok, contract}
      _ -> {:error, {:not_found, "Contract not found"}}
    end
  end

  def get_by_id_with_client_validation(id, %{"type" => type} = params) do
    with {:ok, contract} <- fetch_by_id(id, type),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         {:ok, contract, references} <- load_contract_references(contract) do
      {:ok, contract, references}
    end
  end

  def get_printout_content(%{type: type, contract_request_id: contract_request_id}, client_type, headers) do
    client_id = get_client_id(headers)
    provider = RequestPack.get_provider_by_type(type)

    with {:ok, contract_request} <- provider.fetch_by_id(contract_request_id),
         :ok <-
           ContractRequestsValidator.validate_contract_request_client_access(client_type, client_id, contract_request),
         {:ok, %{"printout_content" => printout_content}} <-
           Storage.decode_and_validate_signed_content(contract_request, headers) do
      {:ok, printout_content}
    end
  end

  def get_employees_by_id(id, params, headers) do
    client_id = get_client_id(headers)

    with %LegalEntity{} = client_legal_entity <- @read_prm_repo.get(LegalEntity, client_id),
         :ok <- validate_legal_entity_is_active(client_legal_entity, :client),
         %CapitationContract{} = contract <- @read_prm_repo.get(CapitationContract, id),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         %Ecto.Changeset{valid?: true, changes: changes} <- ContractEmployeeSearch.changeset(params),
         %Page{entries: contract_employees} = paging <- contract_employee_search(contract, changes) do
      {:ok, paging, load_contract_employees_references(contract_employees)}
    end
  end

  defp contract_employee_search(%CapitationContract{id: contract_id}, search_params) do
    is_active = Map.get(search_params, :is_active)

    params =
      search_params
      |> Map.drop([:is_active, :page_size, :page])
      |> Map.to_list()

    query = if Enum.count(params) > 0, do: where(ContractEmployee, ^params), else: ContractEmployee

    query
    |> where([ce], ce.contract_id == ^contract_id)
    |> add_is_active_query_param(is_active)
    |> @read_prm_repo.paginate(Map.take(search_params, ~w(page page_size)a))
  end

  defp add_is_active_query_param(query, false) do
    where(query, [ce], not (is_nil(ce.end_date) or ce.end_date > ^DateTime.utc_now()))
  end

  defp add_is_active_query_param(query, _) do
    where(query, [ce], is_nil(ce.end_date) or ce.end_date > ^DateTime.utc_now())
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

    contract_schema =
      case Map.get(params, :type, @capitation) do
        @capitation -> CapitationContract
        @reimbursement -> ReimbursementContract
      end

    query = if map_size(params) > 0, do: where(contract_schema, ^Map.to_list(params)), else: contract_schema

    query
    |> add_date_range_at_query(:start_date, date_from_start_date, date_to_start_date)
    |> add_date_range_at_query(:end_date, date_from_end_date, date_to_end_date)
    |> add_legal_entity_id_query(legal_entity_id)
    |> @read_prm_repo.paginate(Map.take(changes, ~w(page page_size)a))
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

  def load_contract_references(%CapitationContract{} = contract) do
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

  def load_contract_references(%ReimbursementContract{} = contract) do
    references =
      Preload.preload_references(contract, [
        {:contractor_legal_entity_id, :legal_entity},
        {:contractor_owner_id, :employee},
        {:nhs_legal_entity_id, :legal_entity},
        {:nhs_signer_id, :employee},
        {:contract_request_id, :reimbursement_contract_request},
        {[:contract_divisions, "$", :division_id], :division}
      ])

    {:ok, contract, references}
  end

  def load_contract_references(nil), do: %{}

  defp changeset(%Search{} = contract, attrs) do
    fields =
      :fields
      |> Search.__schema__()
      |> List.delete(:ids)

    cast(contract, attrs, fields)
  end

  @deprecated "Use CapitationContract.changeset/2 instead"
  defp changeset(%CapitationContract{} = contract, attrs), do: CapitationContract.changeset(contract, attrs)

  @deprecated "Use ReimbursementContract.changeset/2 instead"
  defp changeset(%ReimbursementContract{} = contract, attrs), do: ReimbursementContract.changeset(contract, attrs)

  defp load_contracts_references(contracts) do
    references =
      Preload.preload_references_for_list(contracts, [
        {:contractor_owner_id, :employee}
      ])

    {:ok, references}
  end

  def get_empty_response(params) do
    {:ok,
     %Page{
       entries: [],
       page_number: 1,
       page_size: Map.get(params, "page_size", 50),
       total_entries: 0,
       total_pages: 1
     }, %{}}
  end

  defp load_references(%CapitationContract{} = contract) do
    contract
    |> @read_prm_repo.preload(:contract_employees)
    |> @read_prm_repo.preload(:contract_divisions)
  end

  defp load_references(%ReimbursementContract{} = contract) do
    @read_prm_repo.preload(contract, :contract_divisions)
  end
end
