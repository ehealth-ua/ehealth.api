defmodule EHealth.LegalEntity.API do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  alias Ecto.DateTime
  alias EHealth.API.PRM
  alias EHealth.API.OAuth
  alias EHealth.LegalEntity.Validator
  alias EHealth.EmployeeRequest.API

  require Logger

  @employee_request_status "PENDING_VERIFICATION"
  @employee_request_type "OWNER"

  def create_legal_entity(attrs, headers) do
    attrs
    |> Validator.decode_and_validate()
    |> process_request(headers)
  end

  def process_request({:ok, %{"edrpou" => edrpou} = request_legal_entity}, headers) do
    edrpou
    |> PRM.get_legal_entity_by_edrpou(headers)
    |> create_or_update(request_legal_entity, headers)
    |> update_status(headers)
    |> create_employee_request(request_legal_entity)
    |> fetch_data()
  end
  def process_request(err, _headers), do: err

  @doc """
  Creates new Legal Entity in PRM and Employee request in IL.
  """
  def create_or_update({:ok, %{"data" => []}}, request_legal_entity, headers) do
    consumer_id = get_consumer_id(headers)

    request_legal_entity
    |> Map.merge(%{"status" => "NEW", "inserted_by" => consumer_id, "updated_by" => consumer_id})
    |> PRM.create_legal_entity(headers)
    |> create_oauth_client(headers)
  end

  @doc """
  Updates Legal Entity that exists and creates new Employee request in IL.
  """
  def create_or_update({:ok, %{"data" => [legal_entity]}}, request_legal_entity, headers) do
    request_legal_entity
    |> Map.drop(["edrpou", "kveds"]) # filter immutable data
    |> Map.put("updated_by", get_consumer_id(headers))
    |> PRM.update_legal_entity(Map.fetch!(legal_entity, "id"), headers)
  end

  def create_or_update({:error, _} = err, _, _), do: err

  def update_status({:ok, %{"data" => %{"id" => id, "edrpou" => edrpou}}}, headers) do
    edrpou
    |> PRM.check_msp_state_property_status(headers)
    |> set_legal_entity_status(id, headers)
  end
  def update_status(err, _headers), do: err

  def set_legal_entity_status({:ok, %{"data" => []}}, id, headers) do
    PRM.update_legal_entity(%{"status" => "NOT_VERIFIED"}, id, headers)
  end

  def set_legal_entity_status({:ok, %{"data" => [_edrpou_in_registry]}}, id, headers) do
    PRM.update_legal_entity(%{"status" => "VERIFIED"}, id, headers)
  end

  @doc """
  Creates a new OAuth client for MSP after successfully created a new Legal Entity
  """
  def create_oauth_client({:ok, %{"data" => %{"id" => id, "short_name" => name}}} = legal_entity, headers) do
    client = %{
      "name" => name,
      "user_id" => get_consumer_id(headers),
      "settings" => %{},
      "priv_settings" => %{},
    }
    client
    |> OAuth.create_client()
    |> log_api_error_response(legal_entity, "Cannot create OAuth client for LegalEntity #{id}.")
  end
  def create_oauth_client(err, _headers), do: err

  @doc """
  Create Employee request
  Specification: https://edenlab.atlassian.net/wiki/display/EH/IL.Create+employee+request
  """
  def create_employee_request({:ok, %{"data" => %{"id" => id}}} = legal_entity, %{"owner" => party}) do
    request = %{
      "legal_entity_id" => id,
      "position" => Map.fetch!(party, "position"),
      "status" => @employee_request_status,
      "employee_type" => @employee_request_type,
      "start_date" => DateTime.utc() |> DateTime.to_iso8601(),
      "party" => party
    }

    %{"employee_request" => request}
    |> API.create_employee_request()
    |> log_api_error_response(legal_entity, "Cannot create employee request for LegalEntity #{id}.")
  end
  def create_employee_request(err, _request_data), do: err

  def fetch_data({:ok, %{"data" => data}}), do: {:ok, data}
  def fetch_data(err), do: err

  def get_consumer_id(headers) do
    list = for {k, v} <- headers, k == "x-consumer-id", do: v
    List.first(list)
  end

  def log_api_error_response({:ok, _response}, return, _log_message) do
    return
  end
  def log_api_error_response({:error, response}, return, log_message) do
    Logger.error(fn -> log_message <> " Response: #{inspect response}" end)
    return
  end
end
