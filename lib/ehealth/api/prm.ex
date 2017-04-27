defmodule EHealth.API.PRM do
  @moduledoc """
  PRM API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def process_request_headers(headers) do
    headers ++ [{"Content-Type", "application/json"}]
  end

  def create_legal_entity(data, headers \\ []) do
    "/legal_entities"
    |> post!(Poison.encode!(data), headers)
    |> ResponseDecoder.check_response()
  end

  def update_legal_entity(data, id, headers \\ []) do
    "/legal_entities/#{id}"
    |> patch!(Poison.encode!(data), headers)
    |> ResponseDecoder.check_response()
  end

  def get_legal_entity_by_edrpou(edrpou, headers \\ []) do
    "/legal_entities"
    |> get!(headers, params: [edrpou: edrpou, type: "MSP"])
    |> ResponseDecoder.check_response()
  end

  def check_msp_state_property_status(edrpou, headers \\ []) do
    "/ukr_med_registry"
    |> get!(headers, params: [edrpou: edrpou])
    |> ResponseDecoder.check_response()
  end
end
