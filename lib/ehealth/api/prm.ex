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

  def get_legal_entity_by_edrpou(edrpou) do
    "/legal_entities"
    |> get!([], edrpou: edrpou)
    |> ResponseDecoder.check_response()
    |> get_first()
  end

  def get_first({:ok, list}) do
    List.first(list)
  end
  def get_first(err), do: err
end
