defmodule EHealth.LegalEntities do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  use EHealth.Search, EHealth.PRMRepo

  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import EHealth.Plugs.ClientContext, only: [authorize_legal_entity_id: 3]
  import Ecto.Query, except: [update: 3]

  alias EHealth.PRMRepo
  alias Scrivener.Page
  alias Ecto.Date
  alias Ecto.UUID
  alias EHealth.API.MediaStorage
  alias EHealth.API.Mithril
  alias EHealth.OAuth.API, as: OAuth
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.LegalEntities.Search
  alias EHealth.LegalEntities.Validator
  alias EHealth.EmployeeRequests
  alias EHealth.Employees.Employee
  alias EHealth.Registries
  alias Ecto.Schema.Metadata

  require Logger

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
    mis_verified
  )a

  @optional_fields ~w(
    id
    short_name
    public_name
    phones
    email
    is_active
    nhs_verified
    created_by_mis_client_id
    archive
    receiver_funds_code
    website
    beneficiary
  )a

  @employee_request_status "NEW"

  @status_closed LegalEntity.status(:closed)
  @status_active LegalEntity.status(:active)

  @mis_verified_verified LegalEntity.mis_verified(:verified)
  @mis_verified_not_verified LegalEntity.mis_verified(:not_verified)

  def list(params \\ %{}) do
    %Search{}
    |> changeset(params)
    |> search(params, LegalEntity)
  end

  def get_search_query(LegalEntity = entity, %{ids: _ids} = changes) do
    get_search_query(entity, convert_comma_params_to_where_in_clause(changes, :ids, :id))
  end

  def get_search_query(LegalEntity = entity, %{settlement_id: settlement_id} = changes) when is_binary(settlement_id) do
    changes = Map.put(changes, :settlement_id, {:json_list, [%{settlement_id: settlement_id}]})
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
    |> PRMRepo.one()
  end

  def get_by_id!(id) do
    id
    |> get_by_id_query()
    |> PRMRepo.one!()
  end

  defp get_by_id_query(id) do
    LegalEntity
    |> where([le], le.id == ^id)
    |> join(:left, [le], msp in assoc(le, :medical_service_provider))
    |> preload([le, msp], medical_service_provider: msp)
  end

  def get_by_id(id, headers) do
    client_id = get_client_id(headers)

    with {:ok, client_type} <- Mithril.get_client_type_name(client_id, headers),
         :ok <- authorize_legal_entity_id(id, client_id, client_type),
         {:ok, legal_entity} <- load_legal_entity(id),
         %{} = oauth_client <- OAuth.get_client(legal_entity.id, headers) do
      {:ok, legal_entity, oauth_client}
    end
  end

  def get_by_ids(ids) when is_list(ids) do
    LegalEntity
    |> where([le], le.id in ^ids)
    |> join(:left, [le], msp in assoc(le, :medical_service_provider))
    |> preload([le, msp], medical_service_provider: msp)
    |> PRMRepo.all()
  end

  def create(%LegalEntity{} = legal_entity, attrs, author_id) do
    legal_entity
    |> changeset(attrs)
    |> PRMRepo.insert_and_log(author_id)
  end

  def update(%LegalEntity{} = legal_entity, attrs, author_id) do
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

  def mis_verify(id, consumer_id) do
    update_data = %{mis_verified: @mis_verified_verified}

    with legal_entity <- get_by_id!(id),
         :ok <- check_mis_verify_transition(legal_entity) do
      update(legal_entity, update_data, consumer_id)
    end
  end

  def nhs_verify(id, consumer_id) do
    update_data = %{nhs_verified: true}

    with legal_entity <- get_by_id!(id),
         :ok <- check_nhs_verify_transition(legal_entity) do
      update(legal_entity, update_data, consumer_id)
    end
  end

  defp check_mis_verify_transition(%LegalEntity{mis_verified: @mis_verified_not_verified}), do: :ok

  defp check_mis_verify_transition(_) do
    {:error, {:conflict, "LegalEntity is VERIFIED and cannot be VERIFIED."}}
  end

  defp check_nhs_verify_transition(%LegalEntity{nhs_verified: false}), do: :ok

  defp check_nhs_verify_transition(_) do
    {:error, {:conflict, "LegalEntity is VERIFIED and cannot be VERIFIED."}}
  end

  # Create legal entity

  def create(attrs, headers) do
    with {:ok, request_params} <- Validator.decode_and_validate(attrs, headers),
         edrpou <- Map.fetch!(request_params, "edrpou"),
         type <- Map.fetch!(request_params, "type"),
         legal_entity <- get_or_create_by_edrpou_type(edrpou, type),
         :ok <- check_status(legal_entity),
         {:ok, _} <- store_signed_content(legal_entity.id, attrs, headers),
         request_params <- put_mis_verified_state(request_params),
         {:ok, legal_entity} <- put_legal_entity_to_prm(legal_entity, request_params, headers),
         {:ok, client_type_id} <- get_client_type_id(type, headers),
         {:ok, oauth_client} <- get_oauth_credentials(legal_entity, client_type_id, request_params, headers),
         {:ok, security} <- prepare_security_data(oauth_client),
         {:ok, employee_request} <- create_employee_request(legal_entity, request_params) do
      {:ok,
       %{
         legal_entity: legal_entity,
         employee_request: employee_request,
         security: security
       }}
    end
  end

  defp get_or_create_by_edrpou_type(edrpou, type) do
    case list(%{edrpou: edrpou, type: type}) do
      %Page{entries: []} -> %LegalEntity{id: UUID.generate()}
      %Page{entries: [legal_entity]} -> legal_entity
    end
  end

  defp check_status(%LegalEntity{status: @status_closed}) do
    {:error, {:conflict, "LegalEntity can't be updated"}}
  end

  defp check_status(_), do: :ok

  defp store_signed_content(id, input, headers) do
    input
    |> Map.fetch!("signed_legal_entity_request")
    |> MediaStorage.store_signed_content(:legal_entity_bucket, id, headers)
  end

  defp put_legal_entity_to_prm(%LegalEntity{__meta__: %Metadata{state: :built}} = legal_entity, attrs, headers) do
    # Creates new Legal Entity in PRM
    consumer_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    creation_data =
      Map.merge(attrs, %{
        "status" => @status_active,
        "is_active" => true,
        "inserted_by" => consumer_id,
        "updated_by" => consumer_id,
        "created_by_mis_client_id" => client_id,
        "nhs_verified" => false
      })

    create(legal_entity, creation_data, consumer_id)
  end

  defp put_legal_entity_to_prm(%LegalEntity{__meta__: %Metadata{state: :loaded}} = legal_entity, attrs, headers) do
    # Updates Legal Entity
    consumer_id = get_consumer_id(headers)
    # filter immutable data
    update_data =
      attrs
      |> Map.delete("edrpou")
      |> Map.merge(%{
        "updated_by" => consumer_id,
        "is_active" => true
      })

    update(legal_entity, update_data, consumer_id)
  end

  defp get_oauth_credentials(%LegalEntity{} = legal_entity, client_type_id, request_params, headers) do
    redirect_uri =
      request_params
      |> Map.fetch!("security")
      |> Map.fetch!("redirect_uri")

    OAuth.put_client(legal_entity, client_type_id, redirect_uri, headers)
  end

  defp prepare_security_data(%{"data" => oauth_client}) do
    security = %{
      "client_id" => Map.get(oauth_client, "id"),
      "client_secret" => Map.get(oauth_client, "secret"),
      "redirect_uri" => Map.get(oauth_client, "redirect_uri")
    }

    {:ok, security}
  end

  defp put_mis_verified_state(%{"edrpou" => edrpou, "type" => type} = request_params) do
    Map.put(request_params, "mis_verified", Registries.get_edrpou_verified_status(edrpou, type))
  end

  defp create_employee_request(%LegalEntity{id: id, type: type}, request_params) do
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
    |> EmployeeRequests.create(true)
  end

  defp prepare_employee_request_data(legal_entity_id, party) do
    request = %{
      "legal_entity_id" => legal_entity_id,
      "position" => Map.fetch!(party, "position"),
      "status" => @employee_request_status,
      "start_date" => Date.to_iso8601(Date.utc()),
      "party" => Map.delete(party, "position")
    }

    %{"employee_request" => request}
  end

  defp get_client_type_id(type, headers) do
    case Mithril.get_client_type_by_name(type, headers) do
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
    preload(query, :medical_service_provider)
  end

  defp changeset(%Search{} = legal_entity, attrs) do
    cast(legal_entity, attrs, @search_fields)
  end

  defp changeset(%LegalEntity{} = legal_entity, attrs) do
    legal_entity
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:medical_service_provider)
    |> validate_required(@required_fields)
    |> validate_msp_required()
    |> unique_constraint(:edrpou)
  end

  defp validate_msp_required(%Ecto.Changeset{changes: %{type: "MSP"}} = changeset) do
    validate_required(changeset, [:medical_service_provider])
  end

  defp validate_msp_required(changeset), do: changeset
end
