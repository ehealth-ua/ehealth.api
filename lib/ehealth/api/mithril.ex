defmodule EHealth.API.Mithril do
  @moduledoc """
  Trump API client
  API documentation: http://docs.trump1.apiary.io
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def options, do: config()[:hackney_options]

  def create_client(client) do
    "/admin/clients"
    |> post!(prepare_client_data(client), [], options())
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

  def prepare_client_data(client) do
    Poison.encode!(%{"client" => put_client_type_id(client)})
  end

  def put_client_type_id(client) do
    Map.put(client, "client_type_id", config()[:client_type_id])
  end
end
