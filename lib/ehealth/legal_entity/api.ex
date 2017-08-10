defmodule EHealth.LegalEntity.API do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import EHealth.Plugs.ClientContext, only: [authorize_legal_entity_id: 3]

  alias Ecto.Date
  alias Ecto.UUID
  alias EHealth.API.PRM # Deprecated
  alias EHealth.PRM.Registries
  alias EHealth.API.MediaStorage
  alias EHealth.OAuth.API, as: OAuth
  alias EHealth.LegalEntity.Validator
  alias EHealth.Employee.API
  alias EHealth.API.Mithril

  require Logger

  @employee_request_status "NEW"
  @employee_request_type "OWNER"

  # get legal entity by id

  def get_legal_entity_by_id(id, headers) do
    client_id = get_client_id(headers)
    with {:ok, client_type}  <- get_client_type_name(client_id, headers),
          :ok                <- authorize_legal_entity_id(id, client_id, client_type),
         {:ok, legal_entity} <- load_legal_entity(id, headers),
         %{} = oauth_client  <- OAuth.get_client(Map.fetch!(legal_entity, "id"), headers)
    do
      {:ok, legal_entity, oauth_client}
    end
  end

  def get_client_type_name(client_id, headers) do
    client_id
    |> Mithril.get_client_details(headers)
    |> case do
        {:ok, %{"data" => %{"client_type_name" => client_type_name}}} -> {:ok, client_type_name}
        _ -> {:error, :access_denied}
      end
  end

  defp load_legal_entity(id, headers) do
    %{"id" => id, "is_active" => true}
    |> PRM.get_legal_entities(headers)
    |> case do
         {:ok, %{"data" => []}} -> {:error, :not_found}
         {:ok, %{"data" => data}} -> {:ok, List.first(data)}
         err -> err
       end
  end

  def mis_verify(id, headers) do
    update_data = %{mis_verified: "VERIFIED"}

    with {:ok, pipe_data} <- PRM.get_legal_entity_by_id(id, headers),
         {:ok, _} <- check_mis_verify_transition(pipe_data),
         {:ok, legal_entity} <- PRM.update_legal_entity(update_data, id, headers) do
      {:ok , legal_entity}
    end
  end

  def nhs_verify(id, headers) do
    update_data = %{nhs_verified: true}

    with {:ok, pipe_data} <- PRM.get_legal_entity_by_id(id, headers),
         {:ok, _} <- check_nhs_verify_transition(pipe_data),
         {:ok, legal_entity} <- PRM.update_legal_entity(update_data, id, headers) do
      {:ok , legal_entity}
    end
  end

  def check_mis_verify_transition(%{"data" => %{"mis_verified" => "NOT_VERIFIED"}} = pipe_data) do
    {:ok, pipe_data}
  end
  def check_mis_verify_transition(_) do
    {:error, {:conflict, "LegalEntity is VERIFIED and cannot be VERIFIED."}}
  end

  def check_nhs_verify_transition(%{"data" => %{"nhs_verified" => false}} = pipe_data) do
    {:ok, pipe_data}
  end
  def check_nhs_verify_transition(_) do
    {:error, {:conflict, "LegalEntity is VERIFIED and cannot be VERIFIED."}}
  end

  # get list of legal entities

  def get_legal_entities(params, headers) do
    params
    |> map_legal_entity_id()
    |> PRM.get_legal_entities(headers)
  end

  defp map_legal_entity_id(%{"legal_entity_id" => id} = params), do: Map.put(params, "id", id)
  defp map_legal_entity_id(params), do: params

  # Create legal entity

  def create_legal_entity(attrs, headers) do
    with {:ok, request_params} <- Validator.decode_and_validate(attrs) do
      process_request(request_params, attrs, headers)
    end
  end

  # for testing without signed content
  def process_request(request_params, attrs, headers) do
    edrpou = Map.fetch!(request_params, "edrpou")
    with {:ok, %{"data" => legal_entity}} <- PRM.get_legal_entity_by_edrpou(edrpou, headers),
         legal_entity <- List.first(legal_entity),
         {:ok, id, flow} <- get_legal_entity_id_flow(legal_entity),
         :ok <- check_status(legal_entity),
         {:ok, _} <- store_signed_content(id, attrs, headers),
         request_params <- check_msp_state(request_params),
         {:ok, legal_entity} <- put_legal_entity_to_prm(id, flow, headers, request_params),
         {:ok, oauth_client} <- get_oauth_credentials(legal_entity, request_params, headers),
         {:ok, security} <- prepare_security_data(oauth_client),
         {:ok, employee_request} <- create_employee_request(id, request_params)
    do
      {:ok, %{
        legal_entity: legal_entity,
        employee_request: employee_request,
        security: security,
      }}
    end
  end

  @doc """
  Legal Entity found in PRM. Set flow as update
  """
  def get_legal_entity_id_flow(%{"id" => id}) do
    {:ok, id, :update}
  end

  @doc """
  Legal Entity not found in PRM. Generate ID for Legal Entity. Set flow as create
  """
  def get_legal_entity_id_flow(_) do
    {:ok, UUID.generate(), :create}
  end

  def check_status(%{"status" => "CLOSED"}) do
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
  def put_legal_entity_to_prm(id, :create, headers, request_params) do
    consumer_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    creation_data = %{
      "id" => id,
      "status" => "ACTIVE",
      "is_active" => true,
      "inserted_by" => consumer_id,
      "updated_by" => consumer_id,
      "created_by_mis_client_id" => client_id,
      "nhs_verified" => false,
    }

    request_params
    |> Map.merge(creation_data)
    |> PRM.create_legal_entity(headers)
  end

  @doc """
  Updates Legal Entity that exists and creates new Employee request in IL.
  """
  def put_legal_entity_to_prm(id, :update, headers, request_params) do
    request_params
    |> Map.delete("edrpou") # filter immutable data
    |> Map.merge(%{
        "updated_by" => get_consumer_id(headers),
        "is_active" => true,
      })
    |> PRM.update_legal_entity(id, headers)
  end

  @doc """
  Creates new OAuth client in Mithril API
  """
  def get_oauth_credentials(%{"data" => legal_entity}, request_params, headers) do
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

  def check_msp_state(%{"edrpou" => edrpou} = request_params) do
    Map.put(request_params, "mis_verified", Registries.get_edrpou_verified_status(edrpou))
  end

  @doc """
  Create Employee request
  Specification: https://edenlab.atlassian.net/wiki/display/EH/IL.Create+employee+request
  """
  def create_employee_request(id, request_params) do
    party = Map.fetch!(request_params, "owner")

    id
    |> prepare_employee_request_data(party)
    |> API.create_employee_request()
  end

  def prepare_employee_request_data(legal_entity_id, party) do
    request = %{
        "legal_entity_id" => legal_entity_id,
        "position" => Map.fetch!(party, "position"),
        "status" => @employee_request_status,
        "employee_type" => @employee_request_type,
        "start_date" => Date.to_iso8601(Date.utc()),
        "party" => Map.delete(party, "position"),
      }
    %{"employee_request" => request}
  end
end
