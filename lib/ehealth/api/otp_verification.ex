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

  # Available params:
  #   - phone_number
  #   - statuses
  #
  def search(number, headers \\ []) do
    "/verifications/#{number}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end
end
