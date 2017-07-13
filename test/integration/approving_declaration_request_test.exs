defmodule EHealth.Integraiton.DeclarationRequestApproveTest do
  @moduledoc false

  import Ecto.Changeset

  use EHealth.Web.ConnCase, async: false

  alias EHealth.Repo
  alias EHealth.DeclarationRequest

  describe "Online (OTP) verification" do
    defmodule OtpHappyPath do
      use MicroservicesHelper

      Plug.Router.get "/good_upload_1" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.get "/good_upload_2" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.patch "/verifications/+380972805261/actions/complete" do
        {code, status} =
          case conn.body_params["code"] do
            "12345" ->
              {200, %{status: "verified"}}
            _ ->
              {422, %{}}
          end

        Plug.Conn.send_resp(conn, code, Poison.encode!(%{data: status}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OtpHappyPath)

      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{conn: conn}}
    end

    test "happy path: declaration is successfully approved via OTP code", %{conn: conn} do
      id = Ecto.UUID.generate()

      existing_declaration_request_params = %{
        id: id,
        data: %{
          employee: %{},
          legal_entity: %{
            medical_service_provider: %{}
          },
          division: %{}
        },
        status: "NEW",
        authentication_method_current: %{
          "type" => "OTP",
          "number" => "+380972805261"
        },
        printout_content: "something",
        inserted_by: "f47f94fd-2d77-4b7e-b444-4955812c2a77",
        updated_by: "f47f94fd-2d77-4b7e-b444-4955812c2a77"
      }

      {:ok, _} =
        %DeclarationRequest{}
        |> change(existing_declaration_request_params)
        |> Repo.insert

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve", %{"verification_code" => "12345"})

      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert "APPROVED" = resp["data"]["status"]

      declaration_request = Repo.get(DeclarationRequest, id)

      assert "APPROVED" = declaration_request.status
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" == declaration_request.updated_by
    end
  end

  describe "Offline verification" do
    defmodule OfflineHappyPath do
      use MicroservicesHelper

      Plug.Router.get "/good_upload_1" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.get "/good_upload_2" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.post "/media_content_storage_secrets" do
        params = conn.body_params["secret"]

        [{"port", port}] = :ets.lookup(:uploaded_at_port, "port")

        secret_url =
          case params["resource_name"] do
            "declaration_request_A.jpeg" ->
              "http://localhost:#{port}/good_upload_1"
            "declaration_request_B.jpeg" ->
              "http://localhost:#{port}/good_upload_2"
          end

        resp = %{
          data: %{
            secret_url: secret_url
          }
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(resp))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OfflineHappyPath)

      :ets.new(:uploaded_at_port, [:named_table])
      :ets.insert(:uploaded_at_port, {"port", port})
      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "happy path: declaration is successfully approved via offline docs check", %{conn: conn} do
      id = Ecto.UUID.generate()

      existing_declaration_request_params = %{
        id: id,
        data: %{
          employee: %{},
          legal_entity: %{
            medical_service_provider: %{}
          },
          division: %{}
        },
        status: "NEW",
        authentication_method_current: %{
          "type" => "OFFLINE"
        },
        documents: [
          %{"type" => "A", "verb" => "HEAD"},
          %{"type" => "B", "verb" => "HEAD"}
        ],
        printout_content: "something",
        inserted_by: "f47f94fd-2d77-4b7e-b444-4955812c2a77",
        updated_by: "f47f94fd-2d77-4b7e-b444-4955812c2a77"
      }

      {:ok, _} =
        %DeclarationRequest{}
        |> change(existing_declaration_request_params)
        |> Repo.insert

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve")

      resp = json_response(conn, 200)

      assert "APPROVED" = resp["data"]["status"]

      declaration_request = Repo.get(DeclarationRequest, id)

      assert "APPROVED" = declaration_request.status
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" == declaration_request.updated_by
    end
  end
end
