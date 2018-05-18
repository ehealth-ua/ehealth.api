defmodule EHealth.Unit.DeclarationRequests.API.ResendOTPTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias Ecto.UUID
  alias EHealth.DeclarationRequests.DeclarationRequest
  import EHealth.DeclarationRequests.API.ResendOTP

  defmodule OTPVerificationMock do
    @moduledoc false

    use MicroservicesHelper
    import EHealth.MockServer, only: [wrap_response: 2]

    Plug.Router.post "/verifications" do
      response =
        %{
          id: UUID.generate(),
          status: "new",
          code_expired_at: DateTime.utc_now(),
          active: true
        }
        |> wrap_response(200)
        |> Jason.encode!()

      send_resp(conn, 200, response)
    end
  end

  setup do
    {:ok, port, ref} = start_microservices(OTPVerificationMock)

    System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")

    on_exit(fn ->
      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
      stop_microservices(ref)
    end)

    :ok
  end

  describe "resent_otp" do
    test "invalid id" do
      assert_raise Ecto.NoResultsError, fn ->
        resend_otp(UUID.generate(), [])
      end
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
