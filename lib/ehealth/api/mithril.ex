defmodule EHealth.API.Mithril do
  @moduledoc """
  Trump API client
  API documentation: http://docs.trump1.apiary.io
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  require Logger

  @client_type_name "MSP"
  @client_type_scopes "legal_entities:read,update"
  @client_type_data %{
    "name" => @client_type_name,
    "scope" => @client_type_scopes
  }

  def process_url(url), do: config()[:endpoint] <> url

  def options, do: config()[:hackney_options]

  # Clients

  def create_client(client, headers \\ []) do
    "/admin/clients"
    |> post!(prepare_client_data(client), headers, options())
    |> ResponseDecoder.check_response()
  end

  def get_clients(params \\ [], headers \\ []) do
    "/admin/clients"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_client_by_name(name, headers \\ []) do
    get_clients([name: name], headers)
  end

  # Client types

  def create_client_type(client_type, headers \\ []) do
    "/admin/client_types"
    |> post!(client_type, headers, options())
    |> ResponseDecoder.check_response()
  end

  def get_client_types(params \\ [], headers \\ []) do
    "/admin/client_types"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_client_type_by_name(name, headers \\ []) do
    get_clients([name: name], headers)
  end

  # Helpers

  def prepare_client_data(client) do
    Poison.encode!(%{"client" => put_client_type_id(client)})
  end

  def put_client_type_id(client) do
    Map.put(client, "client_type_id", get_client_type_id())
  end

  def get_client_type_id do
    case get_client_type_by_name(@client_type_name) do
      {:ok, %{"data" => [%{"id" => id}]}}
        -> id
      {:ok, %{"data" => [%{"id" => id} | _tail]}}
        -> id
      {:ok, _}
        -> @client_type_data
           |> create_client_type()
           |> elem(1)
           |> Map.fetch!("data")
           |> Map.fetch!("id")
      {:error, response}
        -> Logger.error(fn -> "Cannot get Client Type from Mithril API. Response: #{inspect response}" end)
        nil
    end
  end
end
