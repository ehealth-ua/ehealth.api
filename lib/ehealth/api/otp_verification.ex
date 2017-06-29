defmodule EHealth.API.OTPVerification do
  @moduledoc """
  OTP Verification API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def initialize(number, headers \\ []) do
    "/verifications/#{number}"
    |> post!("", headers)
    |> ResponseDecoder.check_response()
  end

  def search(number, headers \\ []) do
    "/verifications/#{number}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def complete(number, params, headers \\ []) do
    "/verifications/#{number}/actions/complete"
    |> patch!(Poison.encode!(params), headers)
    |> ResponseDecoder.check_response()
  end
end
