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
    "/search/settlements"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_settlement_by_id(id, headers \\ []) do
    "/settlements/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def get_region_by_id(id, headers \\ []) do
    "/regions/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def get_district_by_id(id, headers \\ []) do
    "/districts/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end
end
