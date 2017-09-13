defmodule EHealth.DeclarationRequest.API.ResendOTP do
  @moduledoc false

  alias EHealth.DeclarationRequest, as: Request
  alias EHealth.API.OTPVerification

  @status_new Request.status(:new)
  @auth_otp Request.authentication_method(:otp)

  def check_status(%Request{status: @status_new} = declaration_request), do: declaration_request
  def check_status(_), do: {:error, [{%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}]}

  def check_auth_method({:error, err}), do: {:error, err}
  def check_auth_method(%Request{authentication_method_current: %{"type" => @auth_otp, "number" => number}}) do
    number
  end
  def check_auth_method(_), do: {:error, [{%{description: "Auth method is not OTP", params: [], rule: :invalid},
    "$.authentication_method_current"}]}

  def init_otp({:error, _} = err, _headers), do: err
  def init_otp(number, headers) do
    with {:ok, %{"data" => data}} <- OTPVerification.initialize(number, headers), do: {:ok, data}
  end
end
