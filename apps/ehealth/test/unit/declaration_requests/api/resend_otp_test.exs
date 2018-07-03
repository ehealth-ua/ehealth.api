defmodule EHealth.Unit.DeclarationRequests.API.ResendOTPTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias Ecto.UUID
  alias EHealth.DeclarationRequests.DeclarationRequest
  import EHealth.DeclarationRequests.API.ResendOTP
  import Mox

  setup :verify_on_exit!

  describe "resent_otp" do
    test "invalid id" do
      refute resend_otp(UUID.generate(), [])
    end

    test "invalid status" do
      declaration_request = insert(:il, :declaration_request, status: DeclarationRequest.status(:approved))

      assert {:error,
              [
                {%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}
              ]} == resend_otp(declaration_request.id, [])
    end

    test "invalid auth method" do
      declaration_request = insert(:il, :declaration_request)

      assert {:error,
              [
                {%{description: "Auth method is not OTP", params: [], rule: :invalid},
                 "$.authentication_method_current"}
              ]} == resend_otp(declaration_request.id, [])
    end

    test "success send otp" do
      expect(OTPVerificationMock, :initialize, fn _number, _headers ->
        {:ok, %{}}
      end)

      declaration_request =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => DeclarationRequest.authentication_method(:otp),
            "number" => "123456789"
          }
        )

      assert {:ok, _} = resend_otp(declaration_request.id, [])
    end
  end
end
