defmodule EHealth.API.OAuth do
  @moduledoc """
  Trump API client
  API documentation: http://docs.trump1.apiary.io
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def options, do: config()[:hackney_options]

  def process_request_headers(headers) do
    headers ++ [{"Content-Type", "application/json"}]
  end

  def create_client(client) do
    "/admin/clients"
    |> post!(prepare_client_data(client), [], options())
    |> ResponseDecoder.check_response()
  end

  def prepare_client_data(client) do
    Poison.encode!(%{"client" => put_client_type_id(client)})
  end

  def put_client_type_id(client) do
    Map.put(client, "client_type_id", config()[:client_type_id])
  end
end
