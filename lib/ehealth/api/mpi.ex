defmodule EHealth.API.MPI do
  @moduledoc """
  MPI API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  # Available params (required):
  #   - first_name (ex.: Олена)
  #   - last_name (ex.: Пчілка)
  #   - birth_date (ex.: 1991-08-19%2000:00:00)
  #   - tax_id (ex.: 3126509816)
  #   - phone_number (ex.: %2B380508887700)
  #
  def search(params \\ %{}, headers \\ []) do
    "/persons"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def person(id, headers \\ []) do
    "/persons/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end
end
