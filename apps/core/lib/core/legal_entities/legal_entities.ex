defmodule Core.LegalEntities do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  use Core.Search, Application.get_env(:core, :repos)[:read_prm_repo]

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Ecto.Query, except: [update: 3]

  alias Core.API.MediaStorage
  alias Core.Context
  alias Core.Contracts.ContractSuspender
  alias Core.EmployeeRequests
  alias Core.Employees.Employee
  alias Core.EventManager
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.LegalEntityCreator
  alias Core.LegalEntities.Search
  alias Core.LegalEntities.SignedContent
  alias Core.LegalEntities.Validator
  alias Core.OAuth.API, as: OAuth
  alias Core.PRMRepo
  alias Scrivener.Page

  require Logger

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]
  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @search_fields ~w(
    id
    ids
    edrpou
    type
    status
    owner_property_type
    legal_form
    nhs_verified
    is_active
    settlement_id
    created_by_mis_client_id
    mis_verified
  )a

  @required_fields ~w(
    name
    status
    type
    owner_property_type
    legal_form
    edrpou
    kveds
    addresses
    inserted_by
    updated_by
    )a

  @optional_fields ~w(
    id
    short_name
    public_name
    phones
    email
    is_active
    status_reason
    reason
    nhs_verified
    nhs_unverified_at
    nhs_reviewed
    nhs_comment
    created_by_mis_client_id
    archive
    receiver_funds_code
    website
    beneficiary
    edr_verified
    mis_verified
    edr_data_id
    accreditation
    license_id
  )a

  @employee_request_status "NEW"

  @status_active LegalEntity.status(:active)
  @status_suspended LegalEntity.status(:suspended)

  def list(params \\ %{}) do
    %Search{}
    |> changeset(params)
    |> search(params, LegalEntity)
  end

  def get_search_query(LegalEntity = entity, %{ids: _ids} = changes) do
    get_search_query(entity, convert_comma_params_to_where_in_clause(changes, :ids, :id))
  end

  def get_search_query(LegalEntity = entity, %{settlement_id: settlement_id} = changes)
      when is_binary(settlement_id) do
    changes =
      changes
      |> Map.put(:addresses, {[%{settlement_id: settlement_id}], :json_list})
      |> Map.delete(:settlement_id)

    get_search_query(entity, changes)
  end

  def get_search_query(entity, changes) do
    entity
    |> super(changes)
    |> load_references()
  end

  def get_by_id(id) do
    id
    |> get_by_id_query()
    |> @read_prm_repo.one()
  end

  def fetch_by_id(id) do
    case get_by_id(id) do
      %LegalEntity{} = legal_entity -> {:ok, legal_entity}
      _ -> {:error, {:not_found, "LegalEntity not found"}}
    end
  end

  def get_by_id!(id) do
    id
    |> get_by_id_query()
    |> @read_prm_repo.one!()
  end

  defp get_by_id_query(id) do
    LegalEntity
    |> where([le], le.id == ^id)
    |> join(:left, [le], msp in assoc(le, :medical_service_provider))
    |> join(:left, [le], l in assoc(le, :license))
    |> preload([le, msp], medical_service_provider: msp)
    |> preload([le, msp, l], license: l)
  end

  def get_by_id(id, headers) do
    client_id = get_client_id(headers)

    with {:ok, client_type} <- @mithril_api.get_client_type_name(client_id, headers),
         :ok <- Context.authorize_legal_entity_id(id, client_id, client_type),
         {:ok, legal_entity} <- load_legal_entity(id) do
      {:ok, legal_entity}
    end
  end

  def get_by_ids(ids) when is_list(ids) do
    LegalEntity
    |> where([le], le.id in ^ids)
    |> join(:left, [le], msp in assoc(le, :medical_service_provider))
    |> preload([le, msp], medical_service_provider: msp)
    |> @read_prm_repo.all()
  end

  def active_by_edr_data_id(edr_data_id) do
    edr_active_statuses = [LegalEntity.status(:active), LegalEntity.status(:suspended)]

    LegalEntity
    |> where([le], le.edr_data_id == ^edr_data_id)
    |> where([le], le.status in ^edr_active_statuses)
    |> @read_prm_repo.all
  end

  def create(%LegalEntity{} = legal_entity, attrs, author_id) do
    legal_entity
    |> changeset(attrs)
    |> PRMRepo.insert_and_log(author_id)
  end

  def update(%LegalEntity{} = legal_entity, attrs, author_id) do
    attrs = Map.put(attrs, :updated_by, author_id)

    legal_entity
    |> changeset(attrs)
    |> PRMRepo.update_and_log(author_id)
  end

  defp load_legal_entity(id) do
    %{"id" => id, "is_active" => true}
    |> list()
    |> case do
      %Page{entries: []} -> {:error, :not_found}
      %Page{entries: data} -> {:ok, List.first(data)}
      err -> err
    end
  end

  def nhs_verify(%{id: id, nhs_verified: nhs_verified}, consumer_id, check_nhs_reviewed? \\ false) do
    with {:ok, legal_entity} <- fetch_by_id(id),
         :ok <- check_legal_entity_active(legal_entity),
         :ok <- check_nhs_verify_transition(legal_entity, nhs_verified),
         :ok <- check_nhs_reviewed(legal_entity, check_nhs_reviewed?) do
      params = nhs_verify_params(nhs_verified)
      update(legal_entity, params, consumer_id)
    end
  end

  defp check_legal_entity_active(%LegalEntity{status: status}) when status != @status_active do
    {:error, {:conflict, "Legal entity is not ACTIVE and cannot be updated"}}
  end

  defp check_legal_entity_active(_), do: :ok

  defp check_nhs_verify_transition(%LegalEntity{nhs_verified: true}, true) do
    {:error, {:conflict, "LegalEntity is VERIFIED and cannot be VERIFIED."}}
  end

  defp check_nhs_verify_transition(_, _), do: :ok

  defp nhs_verify_params(true), do: %{nhs_verified: true, nhs_unverified_at: nil}

  defp nhs_verify_params(false) do
    updated_at = DateTime.utc_now()

    %{nhs_verified: false, nhs_unverified_at: updated_at, updated_at: updated_at}
  end

  # Create legal entity

  def create(params, headers) do
    headers =
      case get_consumer_id(headers) do
        nil -> List.keystore(headers, "x-consumer-id", 0, {"x-consumer-id", Confex.fetch_env!(:core, :system_user)})
        _ -> headers
      end

    with {:ok, request_params, legal_entity_code} <- Validator.decode_and_validate(params, headers),
         %LegalEntityCreator{} = state <-
           LegalEntityCreator.get_or_create(
             request_params,
             legal_entity_code,
             headers
           ) do
      with {:ok, %LegalEntity{} = legal_entity} <-
             PRMRepo.transaction(fn ->
               legal_entity_transaction(state, params["signed_legal_entity_request"], headers)
             end),
           {:ok, client_type_id} <- get_client_type_id(Map.fetch!(request_params, "type"), headers),
           {:ok, client, client_connection} <-
             OAuth.upsert_client_with_connection(legal_entity, client_type_id, request_params, headers),
           {:ok, security} <- prepare_security_data(client, client_connection),
           {:ok, employee_request} <- create_employee_request(legal_entity, request_params) do
        {:ok,
         %{
           legal_entity: legal_entity,
           employee_request: employee_request,
           security: security
         }}
      end
    end
  end

  def legal_entity_transaction(%LegalEntityCreator{} = state, signed_content, headers) do
    legal_entity =
      Enum.reduce(state.inserts ++ state.updates, nil, fn fun, acc ->
        case fun.() do
          {:ok, %LegalEntity{} = legal_entity} ->
            save_signed_content(signed_content, legal_entity.id, headers)
            legal_entity

          {:ok, _} ->
            acc

          {:error, reason} ->
            PRMRepo.rollback(reason)
        end
      end)

    case legal_entity do
      {:ok, legal_entity} ->
        Enum.each(state.update_all, fn fun -> fun.() end)
        {:ok, legal_entity}

      error ->
        error
    end
  end

  defp save_signed_content(signed_content, id, headers) do
    filename = to_string(DateTime.to_unix(DateTime.utc_now()))

    with {:ok, _} <- MediaStorage.store_signed_content(signed_content, :legal_entity_bucket, id, filename, headers),
         {:ok, _} <-
           %SignedContent{}
           |> SignedContent.changeset(%{"filename" => filename, "legal_entity_id" => id})
           |> PRMRepo.insert() do
      :ok
    else
      {:error, reason} -> PRMRepo.rollback(reason)
    end
  end

  def prepare_security_data(client, client_connection) do
    security = %{
      "client_id" => Map.get(client, "id"),
      "client_secret" => Map.get(client_connection, "secret"),
      "redirect_uri" => Map.get(client_connection, "redirect_uri")
    }

    {:ok, security}
  end

  def create_employee_request(%LegalEntity{id: id, type: type}, request_params) do
    # Create Employee request
    # Specification: https://edenlab.atlassian.net/wiki/display/EH/IL.Create+employee+request
    party = Map.fetch!(request_params, "owner")

    employee_type =
      if type == LegalEntity.type(:msp),
        do: Employee.type(:owner),
        else: Employee.type(:pharmacy_owner)

    id
    |> prepare_employee_request_data(party)
    |> put_in(["employee_request", "employee_type"], employee_type)
    |> EmployeeRequests.create_owner()
  end

  def nhs_review(%{id: id}, headers) do
    updated_by = get_consumer_id(headers)

    with {:ok, legal_entity} <- fetch_by_id(id),
         :ok <- check_legal_entity_active(legal_entity),
         :ok <- check_nhs_reviewed_transition(legal_entity),
         {:ok, legal_entity} <- update(legal_entity, %{nhs_reviewed: true}, updated_by) do
      {:ok, legal_entity}
    end
  end

  defp check_nhs_reviewed_transition(%LegalEntity{nhs_reviewed: true}) do
    {:error, {:conflict, "LegalEntity has been already reviewed."}}
  end

  defp check_nhs_reviewed_transition(_), do: :ok

  def nhs_comment(%{id: id, nhs_comment: nhs_comment}, headers) do
    updated_by = get_consumer_id(headers)

    with {:ok, legal_entity} <- fetch_by_id(id),
         :ok <- check_legal_entity_active(legal_entity),
         :ok <- check_nhs_reviewed(legal_entity),
         {:ok, legal_entity} <- update(legal_entity, %{nhs_comment: nhs_comment}, updated_by) do
      {:ok, legal_entity}
    end
  end

  def update_status(%{id: id, status: status, reason: reason}, headers) do
    actor_id = get_consumer_id(headers)
    params = %{status: status, reason: reason, status_reason: "MANUAL_LEGAL_ENTITY_STATUS_UPDATE"}

    PRMRepo.transaction(fn ->
      with {:ok, legal_entity} <- fetch_by_id(id),
           :ok <- check_status_transition(legal_entity.status, status),
           :ok <- maybe_suspend_contracts(legal_entity, status),
           {:ok, legal_entity} <- update(legal_entity, params, actor_id) do
        EventManager.publish_change_status(legal_entity, status, actor_id)

        legal_entity
      else
        {:error, reason} -> PRMRepo.rollback(reason)
      end
    end)
  end

  defp check_status_transition(@status_active, @status_suspended), do: :ok
  defp check_status_transition(@status_suspended, @status_active), do: :ok
  defp check_status_transition(_, _), do: {:error, {:conflict, "Incorrect status transition."}}

  defp maybe_suspend_contracts(legal_entity, @status_suspended) do
    ContractSuspender.suspend_by_contractor_legal_entity_id(legal_entity.id)
  end

  defp maybe_suspend_contracts(_, _), do: :ok

  def check_nhs_reviewed(legal_entity, do_check? \\ true)
  def check_nhs_reviewed(_, false), do: :ok
  def check_nhs_reviewed(%LegalEntity{nhs_reviewed: true}, _), do: :ok
  def check_nhs_reviewed(_, _), do: {:error, {:conflict, "Legal entity should be reviewed first"}}

  def prepare_employee_request_data(legal_entity_id, data) do
    request = %{
      "legal_entity_id" => legal_entity_id,
      "position" => Map.fetch!(data, "position"),
      "status" => @employee_request_status,
      "start_date" => Date.to_iso8601(Date.utc_today()),
      "party" => Map.drop(data, ~w(position employee_id))
    }

    employee_id = data["employee_id"]

    request =
      if employee_id do
        Map.put(request, "employee_id", employee_id)
      else
        request
      end

    %{"employee_request" => request}
  end

  def get_client_type_id(type, headers) do
    case @mithril_api.get_client_type_by_name(type, headers) do
      {:ok, %{"data" => [client_type]}} -> {:ok, Map.get(client_type, "id")}
      _ -> {:error, {:bad_request, "No client type #{type}"}}
    end
  end

  defp convert_comma_params_to_where_in_clause(changes, param_name, db_field) do
    changes
    |> Map.put(db_field, {String.split(changes[param_name], ","), :in})
    |> Map.delete(param_name)
  end

  defp load_references(%Ecto.Query{} = query) do
    query
    |> preload(:license)
    |> preload(:edr_data)
    |> preload(:signed_content_history)
  end

  def changeset(%Search{} = legal_entity, params) do
    cast(legal_entity, params, @search_fields)
  end

  def changeset(%LegalEntity{} = legal_entity, params) do
    legal_entity
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_assoc(:medical_service_provider)
    |> validate_required(@required_fields)
    |> validate_msp_required()
    |> unique_constraint(:edrpou, name: :legal_entities_edrpou_type_status_index)
  end

  defp validate_msp_required(%Ecto.Changeset{changes: %{type: "MSP"}} = changeset) do
    validate_required(changeset, [:medical_service_provider])
  end

  defp validate_msp_required(changeset), do: changeset
end
