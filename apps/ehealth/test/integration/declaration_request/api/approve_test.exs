defmodule EHealth.Integraiton.DeclarationRequest.API.ApproveTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Approve

  describe "verify/2 - via offline docs" do
    defmodule VerifyViaOfflineDocs do
      use MicroservicesHelper

      Plug.Router.post "/media_content_storage_secrets" do
        params = conn.body_params["secret"]

        [{"port", port}] = :ets.lookup(:uploaded_at_port, "port")

        secret_url =
          case params["resource_name"] do
            "declaration_request_person.DECLARATION_FORM.jpeg" -> "http://localhost:#{port}/good_upload_1"
            "declaration_request_A.jpeg" -> "http://localhost:#{port}/good_upload_1"
            "declaration_request_B.jpeg" -> "http://localhost:#{port}/good_upload_2"
            "declaration_request_C.jpeg" -> "http://localhost:#{port}/missing_upload"
          end

        resp = %{
          data: %{
            secret_url: secret_url
          }
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(resp))
      end

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

      :ets.new(:uploaded_at_port, [:named_table])
      :ets.insert(:uploaded_at_port, {"port", port})
      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port}}
    end

    test "all documents were verified to be successfully uploaded" do
      declaration_request = %{
        id: "2685788E-CE5E-4C0F-9857-BB070C5F2180",
        authentication_method_current: %{
          "type" => "OFFLINE"
        },
        documents: [
          %{"verb" => "HEAD", "type" => "A"},
          %{"verb" => "HEAD", "type" => "B"}
        ]
      }

      assert {:ok, true} = verify(declaration_request, "doesn't matter")
    end

    test "there's a missing upload" do
      declaration_request = %{
        id: "2685788E-CE5E-4C0F-9857-BB070C5F2180",
        authentication_method_current: %{
          "type" => "OFFLINE"
        },
        documents: [
          %{"verb" => "HEAD", "type" => "A"},
          %{"verb" => "HEAD", "type" => "C"}
        ]
      }

      assert {:error, {:documents_not_uploaded, ["C"]}} == verify(declaration_request, "doesn't matter")
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

      on_exit(fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      :ok
    end

    test "successfully completes phone verification" do
      declaration_request = %{
        authentication_method_current: %{
          "type" => "OTP",
          "number" => "+380972805261"
        }
      }

      assert {:ok, %{"data" => %{"status" => "verified"}}} == verify_auth(declaration_request, "99911")
    end

    test "phone is not verified verification" do
      declaration_request = %{
        authentication_method_current: %{
          "type" => "OTP",
          "number" => "+380972805261"
        }
      }

      assert {:error, %{"data" => %{}}} == verify_auth(declaration_request, "11999")
    end

    test "auth method NA is not required verification" do
      declaration_request = %{
        authentication_method_current: %{
          "type" => "NA",
          "number" => "+380972805261"
        }
      }

      assert {:ok, true} == verify_auth(declaration_request, nil)
    end
  end
end
