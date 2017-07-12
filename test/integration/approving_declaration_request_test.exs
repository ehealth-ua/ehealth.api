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
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OfflineHappyPath)

      on_exit fn ->
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "happy path: declaration is successfully approved via offline docs check", %{port: port, conn: conn} do
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
          %{"verb" => "HEAD", "url" => "http://localhost:#{port}/good_upload_1"},
          %{"verb" => "HEAD", "url" => "http://localhost:#{port}/good_upload_2"}
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
