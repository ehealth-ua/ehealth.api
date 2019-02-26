defmodule Core.API.OTPVerification do
  @moduledoc """
  OTP Verification API client
  """

  @behaviour Core.API.OTPVerificationBehaviour

  use Core.API.Helpers.MicroserviceBase

  def initialize(params, headers \\ [])

  def initialize(params, headers) when is_map(params) do
    post!("/verifications", Jason.encode!(params), headers)
  end

  def initialize(number, headers) do
    post!("/verifications", Jason.encode!(%{phone_number: number}), headers)
  end

  def search(number, headers \\ []) do
    get!("/verifications/#{number}", headers)
  end

  def complete(number, params, headers \\ []) do
    patch!("/verifications/#{number}/actions/complete", Jason.encode!(params), headers)
  end

  def send_sms(params, headers \\ []) do
    post!("/sms/send", Jason.encode!(params), headers)
  end
end
