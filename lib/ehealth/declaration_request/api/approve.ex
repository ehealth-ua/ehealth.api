defmodule EHealth.DeclarationRequest.API.Approve do
  @moduledoc false

  alias EHealth.Repo
  alias EHealth.API.OTPVerification

  def verify(declaration_request, code) do
    case declaration_request.authentication_method_current do
      %{"type" => "OTP", "number" => phone} ->
        OTPVerification.complete(phone, %{code: code})
      %{"type" => "OFFLINE"} ->
        true
    end
  end
end
