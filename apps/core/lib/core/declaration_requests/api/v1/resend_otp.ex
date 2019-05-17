defmodule Core.DeclarationRequests.API.ResendOTP do
  @moduledoc false

  alias Core.DeclarationRequests
  alias Core.DeclarationRequests.DeclarationRequest

  @rpc_worker Application.get_env(:core, :rpc_worker)

  @status_new DeclarationRequest.status(:new)
  @auth_otp DeclarationRequest.authentication_method(:otp)

  def resend_otp(id) do
    with %DeclarationRequest{} = declaration_request <- DeclarationRequests.get_by_id!(id),
         :ok <- check_status(declaration_request),
         {:ok, number} <- get_otp_number(declaration_request) do
      init_otp(number)
    end
  end

  defp check_status(%DeclarationRequest{status: @status_new}), do: :ok
  defp check_status(_), do: {:error, [{%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}]}

  defp get_otp_number(%DeclarationRequest{authentication_method_current: %{"type" => @auth_otp, "number" => number}}) do
    {:ok, number}
  end

  defp get_otp_number(_),
    do:
      {:error,
       [{%{description: "Auth method is not OTP", params: [], rule: :invalid}, "$.authentication_method_current"}]}

  defp init_otp(number) do
    @rpc_worker.run("otp_verification_api", OtpVerification.Rpc, :initialize, [number])
  end
end
