defmodule EHealth.Integraiton.DeclarationRequest.API.ApproveTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Approve

  describe "verify/2 - via offline docs" do
    defmodule VerifyViaOfflineDocs do
      use MicroservicesHelper

      Plug.Router.get "/good_upload_1" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.get "/good_upload_2" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.get "/missing_upload" do
        Plug.Conn.send_resp(conn, 404, "")
      end
    end

    setup %{conn: _conn} do
      {:ok, port, ref} = start_microservices(VerifyViaOfflineDocs)

      on_exit fn ->
        stop_microservices(ref)
      end

      {:ok, %{port: port}}
    end

    test "all documents were verified to be successfully uploaded", %{port: port} do
      declaration_request = %{
        authentication_method_current: %{
          "type" => "OFFLINE"
        },
        documents: [
          %{"verb" => "HEAD", "url" => "http://localhost:#{port}/good_upload_1"},
          %{"verb" => "HEAD", "url" => "http://localhost:#{port}/good_upload_2"}
        ]
      }

      assert {:ok, true} = verify(declaration_request, "doesn't matter")
    end

    test "there's a missing upload", %{port: port} do
      declaration_request = %{
        authentication_method_current: %{
          "type" => "OFFLINE"
        },
        documents: [
          %{"verb" => "HEAD", "url" => "http://localhost:#{port}/good_upload_1"},
          %{"verb" => "HEAD", "url" => "http://localhost:#{port}/missing_upload"}
        ]
      }

      assert {:error, Enum.at(declaration_request.documents, 1)} ==
        verify(declaration_request, "doesn't matter")
    end
  end

  describe "verify/2 - via code" do
    defmodule VerifyViaOTP do
      use MicroservicesHelper

      Plug.Router.patch "/verifications/+380972805261/actions/complete" do
        {code, status} =
          case conn.body_params["code"] do
            "99911" ->
              {200, %{status: "verified"}}
            "11999" ->
              {422, %{}}
          end

        Plug.Conn.send_resp(conn, code, Poison.encode!(%{data: status}))
      end
    end

    setup %{conn: _conn} do
      {:ok, port, ref} = start_microservices(VerifyViaOTP)

      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "successfully completes phone verification" do
      declaration_request = %{
        authentication_method_current: %{
          "type" => "OTP",
          "number" => "+380972805261"
        }
      }

      assert {:ok, %{"data" => %{"status" => "verified"}}} == verify(declaration_request, "99911")
    end

    test "phone is not verified verification" do
      declaration_request = %{
        authentication_method_current: %{
          "type" => "OTP",
          "number" => "+380972805261"
        }
      }

      assert {:error, %{"data" => %{}}} == verify(declaration_request, "11999")
    end
  end
end
