defmodule EHealth.Integraiton.DeclarationRequestApproveTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  alias EHealth.Repo
  alias EHealth.DeclarationRequests.DeclarationRequest

  describe "Approve declaration with auth type OTP or NA" do
    defmodule OtpHappyPath do
      @moduledoc false

      use MicroservicesHelper
      alias EHealth.MockServer

      Plug.Router.get "/good_upload" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.post "/declarations_count" do
        MockServer.render(%{"count" => 2}, conn, 200)
      end

      Plug.Router.post "/media_content_storage_secrets" do
        params = conn.body_params["secret"]

        [{"port", port}] = :ets.lookup(:uploaded_at_port, "port")

        secret_url =
          case params["resource_name"] do
            "declaration_request_person.DECLARATION_FORM.jpeg" -> "http://localhost:#{port}/good_upload"
          end

        resp = %{
          data: %{
            secret_url: secret_url
          }
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(resp))
      end

      Plug.Router.patch "/verifications/+380972805261/actions/complete" do
        {code, response} =
          case conn.body_params["code"] do
            "12345" ->
              {200, %{data: %{status: "verified"}}}

            "54321" ->
              {404, %{meta: %{code: 404}, error: %{type: "not_found"}}}

            _ ->
              {422, %{meta: %{code: 422}, error: %{type: "forbidden", message: "invalid verification code"}}}
          end

        Plug.Conn.send_resp(conn, code, Poison.encode!(response))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OtpHappyPath)

      :ets.new(:uploaded_at_port, [:named_table])
      :ets.insert(:uploaded_at_port, {"port", port})

      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{conn: conn}}
    end

    test "happy path: declaration is successfully approved via OTP code", %{conn: conn} do
      party = insert(:prm, :party)
      %{id: employee_id} = insert(:prm, :employee, party: party)

      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "OTP",
            "number" => "+380972805261"
          },
          data: %{"employee" => %{"id" => employee_id}}
        )

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve", Poison.encode!(%{"verification_code" => "12345"}))
        |> json_response(200)

      assert id == resp["data"]["id"]
      assert "APPROVED" = resp["data"]["status"]

      declaration_request = Repo.get(DeclarationRequest, id)

      assert "APPROVED" = declaration_request.status
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" == declaration_request.updated_by
    end

    test "declaration is successfully approved without verification", %{conn: conn} do
      party = insert(:prm, :party)
      %{id: employee_id} = insert(:prm, :employee, party: party)

      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "NA",
            "number" => "+380972805261"
          },
          data: %{"employee" => %{"id" => employee_id}}
        )

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve")
        |> json_response(200)

      assert id == resp["data"]["id"]
      assert "APPROVED" = resp["data"]["status"]

      declaration_request = Repo.get(DeclarationRequest, id)

      assert "APPROVED" = declaration_request.status
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" == declaration_request.updated_by
    end

    test "declaration failed to approve: invalid OTP", %{conn: conn} do
      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "OTP",
            "number" => "+380972805261"
          }
        )

      response =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve", Poison.encode!(%{"verification_code" => "invalid"}))
        |> json_response(422)

      assert %{"error" => %{"type" => "forbidden", "message" => _}} = response

      response =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve", Poison.encode!(%{"verification_code" => "54321"}))
        |> json_response(500)

      assert %{"error" => %{"type" => "proxied error", "message" => _}} = response
    end
  end

  describe "Online (OTP) verification when DECLARATION_FORM not uploaded" do
    defmodule OtpNoUploads do
      use MicroservicesHelper

      Plug.Router.get "/no_upload" do
        Plug.Conn.send_resp(conn, 404, "")
      end

      Plug.Router.post "/media_content_storage_secrets" do
        params = conn.body_params["secret"]

        [{"port", port}] = :ets.lookup(:uploaded_at_port, "port")

        secret_url =
          case params["resource_name"] do
            "declaration_request_person.DECLARATION_FORM.jpeg" -> "http://localhost:#{port}/no_upload"
          end

        resp = %{
          data: %{
            secret_url: secret_url
          }
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(resp))
      end

      Plug.Router.patch "/verifications/+380972805261/actions/complete" do
        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: %{status: "verified"}}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OtpNoUploads)

      :ets.new(:uploaded_at_port, [:named_table])
      :ets.insert(:uploaded_at_port, {"port", port})

      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{conn: conn}}
    end

    test "declaration failed to approve: person.DECLARATION_FORM not uploaded", %{conn: conn} do
      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "OTP",
            "number" => "+380972805261"
          }
        )

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve", Poison.encode!(%{"verification_code" => "12345"}))
        |> json_response(409)

      assert "Documents person.DECLARATION_FORM is not uploaded" == resp["error"]["message"]
    end
  end

  describe "Offline verification" do
    defmodule OfflineHappyPath do
      @moduledoc false

      use MicroservicesHelper
      alias EHealth.MockServer

      Plug.Router.post "/declarations_count" do
        MockServer.render(%{"count" => 2}, conn, 200)
      end

      Plug.Router.get "/good_upload_1" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.get "/good_upload_2" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.get "/no_upload" do
        Plug.Conn.send_resp(conn, 404, "")
      end

      Plug.Router.post "/media_content_storage_secrets" do
        params = conn.body_params["secret"]

        [{"port", port}] = :ets.lookup(:uploaded_at_port, "port")

        secret_url =
          case params["resource_name"] do
            "declaration_request_person.DECLARATION_FORM.jpeg" -> "http://localhost:#{port}/good_upload_1"
            "declaration_request_A.jpeg" -> "http://localhost:#{port}/good_upload_1"
            "declaration_request_B.jpeg" -> "http://localhost:#{port}/good_upload_2"
            "declaration_request_404.jpeg" -> "http://localhost:#{port}/no_upload"
            "declaration_request_empty.jpeg" -> "http://localhost:#{port}/no_upload"
            "declaration_request_error.jpeg" -> "http://invalid/route"
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
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "happy path: declaration is successfully approved via offline docs check", %{conn: conn} do
      party = insert(:prm, :party)
      %{id: employee_id} = insert(:prm, :employee, party: party)

      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "OFFLINE"
          },
          data: %{"employee" => %{"id" => employee_id}},
          documents: [
            %{"type" => "A", "verb" => "HEAD"},
            %{"type" => "B", "verb" => "HEAD"}
          ]
        )

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve")
        |> json_response(200)

      assert "APPROVED" = resp["data"]["status"]

      declaration_request = Repo.get(DeclarationRequest, id)

      assert "APPROVED" = declaration_request.status
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" == declaration_request.updated_by
    end

    test "offline documents was not uploaded. Declaration cannot be approved", %{conn: conn} do
      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "OFFLINE"
          },
          documents: [
            %{"type" => "404", "verb" => "HEAD"},
            %{"type" => "empty", "verb" => "HEAD"}
          ]
        )

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve")

      resp = json_response(conn, 409)
      assert "Documents 404, empty is not uploaded" == resp["error"]["message"]
    end

    test "Ael not responding. Declaration cannot be approved", %{conn: conn} do
      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "OFFLINE"
          },
          documents: [
            %{"type" => "empty", "verb" => "HEAD"},
            %{"type" => "error", "verb" => "HEAD"},
            %{"type" => "404", "verb" => "HEAD"}
          ]
        )

      conn
      |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
      |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
      |> patch("/api/declaration_requests/#{id}/actions/approve")
      |> json_response(500)
    end
  end
end
