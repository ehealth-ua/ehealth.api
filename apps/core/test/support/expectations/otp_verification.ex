defmodule Core.Expectations.OtpVerification do
  @moduledoc false

  import Mox
  alias Ecto.UUID

  def expect_otp_verification_verification_phone(result \\ {:ok, %{"data" => %{}}}, n \\ 1) do
    expect(RPCWorkerMock, :run, n, fn "otp_verification_api", OtpVerification.Rpc, :verification_phone, _ ->
      result
    end)
  end

  def expect_otp_verification_initialize do
    expect(RPCWorkerMock, :run, fn "otp_verification_api", OtpVerification.Rpc, :initialize, [_auth_number] ->
      {:ok, %{status: "NEW"}}
    end)
  end

  def expect_otp_verification_complete do
    expect(RPCWorkerMock, :run, fn "otp_verification_api", OtpVerification.Rpc, :complete, [_phone_number, _code] ->
      {:ok, %{}}
    end)
  end

  def expect_otp_verification_send_sms do
    expect(RPCWorkerMock, :run, fn "otp_verification_api", OtpVerification.Rpc, :send_sms, params ->
      destructure([phone_number, body, type], params)

      {:ok,
       %{
         id: UUID.generate(),
         phone_number: phone_number,
         body: body,
         type: type
       }}
    end)
  end
end
