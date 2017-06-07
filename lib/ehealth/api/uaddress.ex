defmodule EHealth.API.UAddress do
  @moduledoc """
  PRM API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def search_settlements(params \\ %{}, headers \\ []) do
    "/settlements"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end
end
