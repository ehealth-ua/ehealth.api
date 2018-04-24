defmodule EHealth.API.OTPVerification do
  @moduledoc """
  OTP Verification API client
  """

  @behaviour EHealth.API.OTPVerificationBehaviour

  use EHealth.API.Helpers.MicroserviceBase

  def initialize(number, headers \\ []) do
    post!("/verifications", Poison.encode!(%{phone_number: number}), headers)
  end

  def search(number, headers \\ []) do
    get!("/verifications/#{number}", headers)
  end

  def complete(number, params, headers \\ []) do
    patch!("/verifications/#{number}/actions/complete", Poison.encode!(params), headers)
  end

  def send_sms(phone_number, body, type, headers \\ []) do
    post!("/sms/send", Poison.encode!(%{phone_number: phone_number, body: body, type: type}), headers)
  end
end
