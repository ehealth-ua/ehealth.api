defmodule EHealth.API.OPS do
  @moduledoc """
  OPS API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def get_declarations(params, headers) do
    "/declarations"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def create_declaration_with_termination_logic(params, headers \\ []) do
    "/declarations/with_termination"
    |> post!(Poison.encode!(params), headers)
    |> ResponseDecoder.check_response()
  end
end
