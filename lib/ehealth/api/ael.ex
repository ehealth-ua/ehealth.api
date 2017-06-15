defmodule EHealth.API.AEL do
  @moduledoc """
  MPI AEL client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def bucket,        do: config()[:bucket]

  def generate_url(resource) do
    headers = [
      {"Content-Type", "application/json"},
      {"location", "http://storage.googleapis.com/#{resource.id}/#{resource.name}?GoogleAccessId=..."}
    ]

    request_body = Poison.encode!(%{
      "secret": %{
        "action": "PUT",
        "bucket": bucket(),
        "resource_id": resource.id,
        "resource_name": resource.name
      }
    })

    "/media_content_storage_secrets"
    |> post!(request_body, headers)
    |> ResponseDecoder.check_response()
  end
end
