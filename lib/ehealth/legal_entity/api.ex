defmodule EHealth.LegalEntity.API do
  @moduledoc """
  The boundary for the LegalEntity system.
  """
  use OkJose
  use Confex, otp_app: :ehealth

  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import EHealth.Utils.Pipeline

  alias Ecto.Date
  alias Ecto.UUID
  alias EHealth.API.PRM
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
    {:ok, %{
      params: put_is_active(%{"id" => id}),
      headers: headers,
      client_id: get_client_id(headers)
    }}
    |> get_client_type_name()
    |> authorize_id
    |> prepare_legal_entities_params()
    |> load_legal_entity()
    |> put_oauth_client()
    |> ok()
    |> normalize_legal_entities()
  end

  defp authorize_id(%{client_type: client_type, params: %{"id" => id}, client_id: client_id} = pipe_data) do
    if client_type in config()[:tokens_types_personal] and id != client_id do
      {:error, :forbidden}
    else
      {:ok, pipe_data}
    end
  end

  defp load_legal_entity(%{params: params, headers: headers} = pipe_data) do
    params
    |> PRM.get_legal_entities(headers)
    |> case do
         {:ok, %{"data" => []}} -> {:error, :not_found}
         {:ok, %{"data" => data}} -> data |> List.first() |> put_in_pipe(:legal_entity, pipe_data)
         err -> err
       end
  end

  def put_oauth_client(%{legal_entity: %{"id" => id}, headers: headers} = pipe_data) do
    id
    |> OAuth.get_client(headers)
    |> put_in_pipe(:client, pipe_data)
  end

  # get list of legal entities

  def get_legal_entities(params, headers) do
    {:ok, %{
      params: params |> put_is_active() |> convert_legal_entity_id_param(),
      headers: headers,
      client_id: get_client_id(headers)
    }}
    |> get_client_type_name()
    |> prepare_legal_entities_params()
    |> load_legal_entities()
    |> ok()
    |> normalize_legal_entities()
  end

  defp put_is_active(params), do: Map.put(params, "is_active", true)

  defp convert_legal_entity_id_param(%{"legal_entity_id" => id} = params), do: Map.put(params, "id", id)
  defp convert_legal_entity_id_param(params), do: params

  def get_client_type_name(%{client_id: client_id, headers: headers} = pipe_data) do
    client_id
    |> Mithril.get_client_details(headers)
    |> case do
        {:ok, %{"data" => %{"client_type_name" => client_type_name}}} ->
          put_in_pipe(client_type_name, :client_type, pipe_data)

        err -> err
      end
  end

  defp prepare_legal_entities_params(%{client_type: client_type, params: params, client_id: client_id} = pipe_data) do
    conf = config()
    params =
      cond do
        client_type in conf[:tokens_types_personal] -> Map.put(params, "id", client_id)
        client_type in conf[:tokens_types_mis] -> params
        client_type in conf[:tokens_types_admin] -> params
        true ->
          Logger.error(fn -> "Undefined client type name #{client_type} for /legal_entities. " <>
                "Cannot prepare params for request to PRM" end)
          Map.put(params, "id", client_id)
      end

    put_in_pipe(params, :params, pipe_data)
  end

  defp load_legal_entities(%{params: params, headers: headers} = pipe_data) do
    params
    |> PRM.get_legal_entities(headers)
    |> put_success_api_response_in_pipe(:legal_entities, pipe_data)
  end

  defp normalize_legal_entities({:ok, %{legal_entity: legal_entity, client: client}}), do: {:ok, legal_entity, client}
  defp normalize_legal_entities({:ok, %{legal_entities: legal_entities}}), do: {:ok, legal_entities}
  defp normalize_legal_entities(err), do: err

  # Create legal entity

  def create_legal_entity(attrs, headers) do
    attrs
    |> Validator.decode_and_validate()
    |> process_request(attrs, headers)
  end

  # for testing without signed content
  def process_request({:ok, _} = pipe_data, attrs, headers) do
    pipe_data
    |> search_legal_entity_in_prm(headers)
    |> prepare_legal_entity_id()
    |> store_signed_content(attrs, headers)
    |> check_msp_state(headers)
    |> put_legal_entity_to_prm(headers)
    |> get_oauth_credentials(headers)
    |> prepare_security_data()
    |> create_employee_request()
  end
  def process_request({:error, _} = err, _attrs, _headers), do: err
  def process_request(err, _attrs, _headers), do: {:error, err}

  def search_legal_entity_in_prm({:ok, %{legal_entity_request: %{"edrpou" => edrpou}} = pipe_data}, headers) do
    edrpou
    |> PRM.get_legal_entity_by_edrpou(headers)
    |> put_success_api_response_in_pipe(:legal_entity_prm, pipe_data)
  end

  @doc """
  Legal Entity not found in PRM. Generate ID for Legal Entity. Set flow as create
  """
  def prepare_legal_entity_id({:ok, %{legal_entity_prm: %{"data" => []}} = pipe_data}) do
    data = %{
      legal_entity_id: UUID.generate(),
      legal_entity_flow: :create
    }
    {:ok, Map.merge(pipe_data, data)}
  end

  @doc """
  Legal Entity found in PRM. Set flow as update
  """
  def prepare_legal_entity_id({:ok, %{legal_entity_prm: %{"data" => [legal_entity]}} = pipe_data}) do
    data = %{
      legal_entity_id: Map.fetch!(legal_entity, "id"),
      legal_entity_flow: :update
    }
    {:ok, Map.merge(pipe_data, data)}
  end

  def prepare_legal_entity_id(err), do: err

  @doc """
  Creates signed url and store signed content in GCS
  """
  def store_signed_content({:ok, pipe_data}, input, headers) do
    input
    |> Map.fetch!("signed_legal_entity_request")
    |> MediaStorage.store_signed_content(:legal_entity_bucket, Map.fetch!(pipe_data, :legal_entity_id), headers)
    |> validate_api_response(pipe_data, "Cannot store signed content")
  end
  def store_signed_content(err, _input, _headers), do: err

  @doc """
  Creates new Legal Entity in PRM
  """
  def put_legal_entity_to_prm({:ok, %{legal_entity_flow: :create} = pipe_data}, headers) do
    consumer_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    creation_data = %{
      "id" => Map.fetch!(pipe_data, :legal_entity_id),
      "status" => "ACTIVE",
      "is_active" => true,
      "inserted_by" => consumer_id,
      "updated_by" => consumer_id,
      "created_by_mis_client_id" => client_id,
      "nhs_verified" => false,
    }

    pipe_data
    |> Map.fetch!(:legal_entity_request)
    |> Map.merge(creation_data)
    |> PRM.create_legal_entity(headers)
    |> put_success_api_response_in_pipe(:legal_entity_prm, pipe_data)
  end

  @doc """
  Updates Legal Entity that exists and creates new Employee request in IL.
  """
  def put_legal_entity_to_prm({:ok, %{legal_entity_flow: :update} = pipe_data}, headers) do
    pipe_data
    |> Map.fetch!(:legal_entity_request)
    |> Map.drop(["edrpou"]) # filter immutable data
    |> Map.merge(%{
        "updated_by" => get_consumer_id(headers),
        "is_active" => true,
      })
    |> PRM.update_legal_entity(Map.fetch!(pipe_data, :legal_entity_id), headers)
    |> put_success_api_response_in_pipe(:legal_entity_prm, pipe_data)
  end
  def put_legal_entity_to_prm(err, _headers), do: err

  @doc """
  Creates new OAuth client in Mithril API
  """
  def get_oauth_credentials({:ok, pipe_data}, headers) do
    redirect_uri =
      pipe_data
      |> Map.fetch!(:legal_entity_request)
      |> Map.fetch!("security")
      |> Map.fetch!("redirect_uri")

    pipe_data
    |> Map.fetch!(:legal_entity_prm)
    |> Map.fetch!("data")
    |> OAuth.put_client(redirect_uri, headers)
    |> put_success_api_response_in_pipe(:oauth_client, pipe_data)
  end

  def get_oauth_credentials(err, _headers), do: err

  def prepare_security_data({:ok, pipe_data}) do
    oauth_client = pipe_data |> Map.fetch!(:oauth_client) |> Map.fetch!("data")

    security = %{
      "client_id" => Map.get(oauth_client, "id"),
      "client_secret" => Map.get(oauth_client, "secret"),
      "redirect_uri" => Map.get(oauth_client, "redirect_uri")
    }

    put_in_pipe(security, :security, pipe_data)
  end
  def prepare_security_data(err), do: err

  def check_msp_state({:ok, pipe_data}, headers) do
    pipe_data
    |> Map.fetch!(:legal_entity_request)
    |> Map.fetch!("edrpou")
    |> PRM.check_msp_state_property_status(headers)
    |> set_legal_entity_mis_verified(pipe_data)
  end
  def check_msp_state(err, _headers), do: err

  @doc """
  Set mis_verified for legal_entity without edrpou in registry
  """
  def set_legal_entity_mis_verified({:ok, %{"data" => []}}, pipe_data) do
    {:ok, put_in(pipe_data[:legal_entity_request]["mis_verified"], "NOT_VERIFIED")}
  end

  @doc """
  Set mis_verified for legal_entity with edrpou in registry
  """
  def set_legal_entity_mis_verified({:ok, %{"data" => [_edrpou_in_registry]}}, pipe_data) do
    {:ok, put_in(pipe_data[:legal_entity_request]["mis_verified"], "VERIFIED")}
  end

  @doc """
  Create Employee request
  Specification: https://edenlab.atlassian.net/wiki/display/EH/IL.Create+employee+request
  """
  def create_employee_request({:ok, pipe_data}) do
    id = Map.fetch!(pipe_data, :legal_entity_id)
    party =
      pipe_data
      |> Map.fetch!(:legal_entity_request)
      |> Map.fetch!("owner")

    id
    |> prepare_employee_request_data(party)
    |> API.create_employee_request()
    |> put_success_api_response_in_pipe(:employee_request, pipe_data)
  end
  def create_employee_request(err), do: err

  def prepare_employee_request_data(legal_entity_id, party) do
    request = %{
        "legal_entity_id" => legal_entity_id,
        "position" => Map.fetch!(party, "position"),
        "status" => @employee_request_status,
        "employee_type" => @employee_request_type,
        "start_date" => Date.to_iso8601(Date.utc()),
        "party" => party
      }
    %{"employee_request" => request}
  end
end
