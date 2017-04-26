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

  def create_legal_entity(data) do
    "/legal_entities"
    |> post!(Poison.encode!(data))
    |> ResponseDecoder.check_response()
  end

  def update_legal_entity(data, id) do
    "/legal_entities/#{id}"
    |> patch!(Poison.encode!(data))
    |> ResponseDecoder.check_response()
  end

  def get_legal_entity_by_edrpou(edrpou) do
    "/legal_entities"
    |> get!([], params: [edrpou: edrpou, type: "MSP"])
    |> ResponseDecoder.check_response()
  end
end
