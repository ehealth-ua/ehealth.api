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

  def create_declaration_with_termination_logic(params, headers \\ []) do
    "/declarations/create_with_termination_logic"
    |> post!(Poison.encode!(params), headers)
    |> ResponseDecoder.check_response()
  end
end
