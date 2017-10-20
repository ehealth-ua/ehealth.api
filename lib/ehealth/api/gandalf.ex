defmodule EHealth.API.Gandalf do
  @moduledoc """
  MPI API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def client_id,      do: config()[:client_id]
  def client_secret,  do: config()[:client_secret]
  def table_id,       do: config()[:table_id]
  def application_id, do: config()[:application_id]

  def decide_auth_method(phone_availability, preferable_auth_method) do
    headers = [
      {"X-Application", application_id()}
    ]

    basic_auth = Keyword.merge(
      [hackney: [basic_auth: {client_id(), client_secret()}]],
      config()[:hackney_options]
    )

    request_body = Poison.encode!(%{
      phone_availability: phone_availability,
      preferable_auth_method: preferable_auth_method
    })

    try do
      "/api/v1/tables/#{table_id()}/decisions"
      |> post!(request_body, headers, basic_auth)
      |> ResponseDecoder.check_response()
    rescue
      HTTPoison.Error ->
        {:ok, :fallback_to_default}
    end
  end
end
