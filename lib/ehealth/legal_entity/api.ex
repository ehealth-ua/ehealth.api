defmodule EHealth.LegalEntity.API do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import EHealth.Plugs.ClientContext, only: [authorize_legal_entity_id: 3]

  alias Ecto.Date
  alias Ecto.UUID
  alias EHealth.PRM.Registries
  alias EHealth.API.MediaStorage
  alias EHealth.OAuth.API, as: OAuth
  alias EHealth.LegalEntity.Validator
  alias EHealth.Employee.API
  alias EHealth.API.Mithril
  alias EHealth.PRM.LegalEntities
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias Ecto.Schema.Metadata

  require Logger

  @employee_request_status "NEW"

  @status_closed "CLOSED"
  @status_active "ACTIVE"

  # get legal entity by id

  def get_legal_entity_by_id(id, headers) do
    client_id = get_client_id(headers)
    with {:ok, client_type}  <- get_client_type_name(client_id, headers),
          :ok                <- authorize_legal_entity_id(id, client_id, client_type),
         {:ok, legal_entity} <- load_legal_entity(id),
         %{} = oauth_client  <- OAuth.get_client(legal_entity.id, headers)
    do
      {:ok, legal_entity, oauth_client}
    end
  end

  def get_client_type_name(client_id, headers) do
    case Mithril.get_client_details(client_id, headers) do
      {:ok, %{"data" => %{"client_type_name" => client_type_name}}} -> {:ok, client_type_name}
      _ -> {:error, :access_denied}
    end
  end

  defp load_legal_entity(id) do
    %{"id" => id, "is_active" => true}
    |> LegalEntities.get_legal_entities
    |> case do
         {[], _} -> {:error, :not_found}
         {data, _} -> {:ok, List.first(data)}
         err -> err
       end
  end

  def mis_verify(id, consumer_id) do
    update_data = %{mis_verified: "VERIFIED"}

    with legal_entity <- LegalEntities.get_legal_entity_by_id!(id),
         :ok <- check_mis_verify_transition(legal_entity)
    do
      LegalEntities.update_legal_entity(legal_entity, update_data, consumer_id)
    end
  end

  def nhs_verify(id, consumer_id) do
    update_data = %{nhs_verified: true}

    with legal_entity <- LegalEntities.get_legal_entity_by_id!(id),
         :ok <- check_nhs_verify_transition(legal_entity)
    do
      LegalEntities.update_legal_entity(legal_entity, update_data, consumer_id)
    end
  end

  def check_mis_verify_transition(%LegalEntity{mis_verified: "NOT_VERIFIED"}), do: :ok
  def check_mis_verify_transition(_) do
    {:error, {:conflict, "LegalEntity is VERIFIED and cannot be VERIFIED."}}
  end

  def check_nhs_verify_transition(%LegalEntity{nhs_verified: false}), do: :ok
  def check_nhs_verify_transition(_) do
    {:error, {:conflict, "LegalEntity is VERIFIED and cannot be VERIFIED."}}
  end

  # get list of legal entities

  def get_legal_entities(params) do
    params
    |> map_legal_entity_id()
    |> LegalEntities.get_legal_entities()
  end

  defp map_legal_entity_id(%{"legal_entity_id" => id} = params), do: Map.put(params, "id", id)
  defp map_legal_entity_id(params), do: params

  # Create legal entity

  def create_legal_entity(attrs, headers) do
    with {:ok, request_params}   <- Validator.decode_and_validate(attrs),
         legal_entity            <- get_or_create_by_edrpou(Map.fetch!(request_params, "edrpou")),
         :ok                     <- check_status(legal_entity),
         {:ok, _}                <- store_signed_content(legal_entity.id, attrs, headers),
         request_params          <- put_mis_verified_state(request_params),
         {:ok, legal_entity}     <- put_legal_entity_to_prm(legal_entity, request_params, headers),
         {:ok, oauth_client}     <- get_oauth_credentials(legal_entity, request_params, headers),
         {:ok, security}         <- prepare_security_data(oauth_client),
         {:ok, employee_request} <- create_employee_request(legal_entity, request_params)
    do
      {:ok, %{
          legal_entity: legal_entity,
          employee_request: employee_request,
          security: security,
      }}
    end
  end

  defp get_or_create_by_edrpou(edrpou) do
    case LegalEntities.get_legal_entity_by_edrpou(edrpou) do
      %LegalEntity{} = legal_entity -> legal_entity
      _ -> %LegalEntity{id: UUID.generate()}
    end
  end

  def check_status(%LegalEntity{status: @status_closed}) do
    {:error, {:conflict, "LegalEntity can't be updated"}}
  end
  def check_status(_), do: :ok

  @doc """
  Creates signed url and store signed content in GCS
  """
  def store_signed_content(id, input, headers) do
    input
    |> Map.fetch!("signed_legal_entity_request")
    |> MediaStorage.store_signed_content(:legal_entity_bucket, id, headers)
  end

  @doc """
  Creates new Legal Entity in PRM
  """
  def put_legal_entity_to_prm(%LegalEntity{__meta__: %Metadata{state: :built}} = legal_entity, attrs, headers) do
    consumer_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    creation_data = Map.merge(attrs, %{
      "status" => @status_active,
      "is_active" => true,
      "inserted_by" => consumer_id,
      "updated_by" => consumer_id,
      "created_by_mis_client_id" => client_id,
      "nhs_verified" => false,
    })

    LegalEntities.create_legal_entity(legal_entity, creation_data, consumer_id)
  end

  @doc """
  Updates Legal Entity
  """
  def put_legal_entity_to_prm(%LegalEntity{__meta__: %Metadata{state: :loaded}} = legal_entity, attrs, headers) do
    consumer_id = get_consumer_id(headers)
    update_data =
      attrs
      |> Map.delete("edrpou") # filter immutable data
      |> Map.merge(%{
        "updated_by" => consumer_id,
        "is_active" => true,
      })

    LegalEntities.update_legal_entity(legal_entity, update_data, consumer_id)
  end

  @doc """
  Creates new OAuth client in Mithril API
  """
  def get_oauth_credentials(%LegalEntity{} = legal_entity, request_params, headers) do
    redirect_uri =
      request_params
      |> Map.fetch!("security")
      |> Map.fetch!("redirect_uri")

    OAuth.put_client(legal_entity, redirect_uri, headers)
  end

  def prepare_security_data(%{"data" => oauth_client}) do
    security = %{
      "client_id" => Map.get(oauth_client, "id"),
      "client_secret" => Map.get(oauth_client, "secret"),
      "redirect_uri" => Map.get(oauth_client, "redirect_uri")
    }

    {:ok, security}
  end

  def put_mis_verified_state(%{"edrpou" => edrpou} = request_params) do
    Map.put(request_params, "mis_verified", Registries.get_edrpou_verified_status(edrpou))
  end

  @doc """
  Create Employee request
  Specification: https://edenlab.atlassian.net/wiki/display/EH/IL.Create+employee+request
  """
  def create_employee_request(%LegalEntity{id: id, type: type}, request_params) do
    party = Map.fetch!(request_params, "owner")
    employee_type = if type == LegalEntity.type(:msp),
      do: Employee.type(:owner),
      else: Employee.type(:pharmacy_owner)

    id
    |> prepare_employee_request_data(party)
    |> put_in(["employee_request", "employee_type"], employee_type)
    |> API.create_employee_request()
  end

  def prepare_employee_request_data(legal_entity_id, party) do
    request = %{
      "legal_entity_id" => legal_entity_id,
      "position" => Map.fetch!(party, "position"),
      "status" => @employee_request_status,
      "start_date" => Date.to_iso8601(Date.utc()),
      "party" => Map.delete(party, "position"),
    }
    %{"employee_request" => request}
  end
end
