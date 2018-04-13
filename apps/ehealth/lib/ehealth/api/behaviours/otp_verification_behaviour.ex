defmodule EHealth.API.OTPVerificationBehaviour do
  @moduledoc false

  @callback initialize(number :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback search(number :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback complete(number :: binary, params :: term, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback send_sms(phone_number :: binary, body :: binary, type :: binary, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
end
