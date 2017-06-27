defmodule EHealth.LegalEntity.API do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

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

  def get_legal_entity_by_id(id, headers) do
    client_id = get_client_id(headers)
    client_type = Mithril.get_client_type_name(client_id)
    case id == client_id or client_type == "MIS" do
      true ->
        id
        |> PRM.get_legal_entity_by_id(headers)
        |> legal_entity_is_active()
        |> OAuth.get_client(headers)
        |> fetch_data()
      _ -> {:error, :forbidden}
    end
  end

  def get_legal_entities(params, headers) do
    client_id = get_client_id(headers)
    params = Map.put(params, "is_active", true)
    case Mithril.get_client_type_name(client_id) == "MIS" do
      true -> PRM.get_legal_entities(params, headers)
      _ -> {:ok, get_legal_entity_list_by_id(client_id, headers)}
    end
  end

  def get_legal_entity_list_by_id(nil, _headers), do: []
  def get_legal_entity_list_by_id(id, headers) do
    id
    |> get_legal_entity_by_id(headers)
    |> fetch_to_list()
  end

  def legal_entity_is_active({:ok, %{"data" => data}} = resp) do
    case Map.fetch!(data, "is_active") do
      true -> resp
      false -> {:error, :not_found}
    end
  end
  def legal_entity_is_active(err), do: err

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
    |> put_legal_entity_to_prm(headers)
    |> get_oauth_credentials(headers)
    |> prepare_security_data()
    |> update_legal_entity_status(headers)
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
    |> MediaStorage.store_signed_content(Map.fetch!(pipe_data, :legal_entity_id), headers)
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
      "status" => "NEW",
      "is_active" => true,
      "inserted_by" => consumer_id,
      "updated_by" => consumer_id,
      "created_by_mis_client_id" => client_id
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

  def update_legal_entity_status({:ok, pipe_data}, headers) do
    pipe_data
    |> Map.fetch!(:legal_entity_prm)
    |> Map.fetch!("data")
    |> Map.fetch!("edrpou")
    |> PRM.check_msp_state_property_status(headers)
    |> set_legal_entity_status(Map.fetch!(pipe_data, :legal_entity_id), headers)
    |> put_success_api_response_in_pipe(:legal_entity_prm, pipe_data)
  end
  def update_legal_entity_status(err, _headers), do: err

  def set_legal_entity_status({:ok, %{"data" => []}}, id, headers) do
    PRM.update_legal_entity(%{"status" => "NOT_VERIFIED"}, id, headers)
  end

  def set_legal_entity_status({:ok, %{"data" => [_edrpou_in_registry]}}, id, headers) do
    PRM.update_legal_entity(%{"status" => "VERIFIED"}, id, headers)
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

  def fetch_data({:ok, %{"data" => data}, secret}), do: {:ok, data, secret}
  def fetch_data(err), do: err

  def fetch_to_list({:ok, data, _secret}), do: [data]
  def fetch_to_list(_err), do: []
end
