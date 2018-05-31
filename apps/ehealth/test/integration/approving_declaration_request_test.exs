defmodule EHealth.Integraiton.DeclarationRequestApproveTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  alias EHealth.Repo
  alias EHealth.DeclarationRequests.DeclarationRequest
  import Mox

  describe "Approve declaration with auth type OTP or NA" do
    defmodule OtpHappyPath do
      @moduledoc false

      use MicroservicesHelper
      alias EHealth.MockServer

      Plug.Router.post "/declarations_count" do
        MockServer.render(%{"count" => 2}, conn, 200)
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

        Plug.Conn.send_resp(conn, code, Jason.encode!(response))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OtpHappyPath)

      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{conn: conn}}
    end

    test "happy path: declaration is successfully approved via OTP code", %{conn: conn} do
      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 10}}}
      end)

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
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve", Jason.encode!(%{"verification_code" => "12345"}))
        |> json_response(200)

      assert id == resp["data"]["id"]
      assert "APPROVED" = resp["data"]["status"]

      declaration_request = Repo.get(DeclarationRequest, id)

      assert "APPROVED" = declaration_request.status
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" == declaration_request.updated_by
    end

    test "declaration is successfully approved without verification", %{conn: conn} do
      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 10}}}
      end)

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
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
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
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve", Jason.encode!(%{"verification_code" => "invalid"}))
        |> json_response(422)

      assert %{"error" => %{"type" => "forbidden", "message" => _}} = response

      response =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve", Jason.encode!(%{"verification_code" => "54321"}))
        |> json_response(500)

      assert %{"error" => %{"type" => "proxied error", "message" => _}} = response
    end
  end

  describe "Online (OTP) verification when DECLARATION_FORM not uploaded" do
    defmodule OtpNoUploads do
      use MicroservicesHelper

      Plug.Router.patch "/verifications/+380972805261/actions/complete" do
        Plug.Conn.send_resp(conn, 200, Jason.encode!(%{data: %{status: "verified"}}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OtpNoUploads)
      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{conn: conn}}
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
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OfflineHappyPath)
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "happy path: declaration is successfully approved via offline docs check", %{conn: conn} do
      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 10}}}
      end)

      expect(MediaStorageMock, :create_signed_url, 3, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 3, fn _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

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
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve")
        |> json_response(200)

      assert "APPROVED" = resp["data"]["status"]

      declaration_request = Repo.get(DeclarationRequest, id)

      assert "APPROVED" = declaration_request.status
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" == declaration_request.updated_by
    end

    test "offline documents was not uploaded. Declaration cannot be approved", %{conn: conn} do
      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, _ ->
        {:ok, %HTTPoison.Response{status_code: 404}}
      end)

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
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
        |> patch("/api/declaration_requests/#{id}/actions/approve")

      resp = json_response(conn, 409)
      assert "Documents 404, empty is not uploaded" == resp["error"]["message"]
    end

    test "Ael not responding. Declaration cannot be approved", %{conn: conn} do
      expect(MediaStorageMock, :create_signed_url, 3, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 3, fn _, _ ->
        {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
      end)

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
      |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
      |> patch("/api/declaration_requests/#{id}/actions/approve")
      |> json_response(500)
    end
  end
end
