defmodule EHealth.API.PRM do
  @moduledoc """
  PRM API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth

  alias EHealth.API.ResponseDecoder

  @filter_headers ["content-length", "Content-Length"]

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def process_request_headers(headers) do
    headers
    |> Keyword.drop(@filter_headers)
    |> Kernel.++([{"Content-Type", "application/json"}])
  end

  def create_legal_entity(data, headers \\ []) do
    "/legal_entities"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_legal_entity(data, id, headers \\ []) do
    "/legal_entities/#{id}"
    |> patch!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_legal_entities(params \\ [], headers \\ []) do
    "/legal_entities"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_legal_entity_by_id(id, headers \\ []) do
    "/legal_entities/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def get_legal_entity_by_edrpou(edrpou, headers \\ []) do
    get_legal_entities([edrpou: edrpou, type: "MSP"], headers)
  end

  def check_msp_state_property_status(edrpou, headers \\ []) do
    "/ukr_med_registry"
    |> get!(headers, params: [edrpou: edrpou])
    |> ResponseDecoder.check_response()
  end
end
