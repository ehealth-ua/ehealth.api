defmodule Mithril.Web.RegistrationControllerTest do
  use EHealth.Web.ConnCase

  import Mox
  import EHealth.Guardian

  # For Mox lib. Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "send verification email" do
    test "invalid email", %{conn: conn} do
      assert "$.email" ==
               conn
               |> post(cabinet_path(conn, :email_verification), %{email: "invalid"})
               |> json_response(422)
               |> get_in(~w(error invalid))
               |> hd()
               |> Map.get("entry")
    end

    test "user with passed email already exists", %{conn: conn} do
      email = "test@example.com"

      expect(MithrilMock, :search_user, fn %{email: "test@example.com"} ->
        {:ok, %{"data" => [%{"tax_id" => "23451234"}]}}
      end)

      assert "User with this email already exists" ==
               conn
               |> post(cabinet_path(conn, :email_verification), %{email: email})
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "user with passed email already exists but tax_id is empty", %{conn: conn} do
      email = "success-new-user@example.com"

      expect(MithrilMock, :search_user, fn %{email: ^email} ->
        {:ok, %{"data" => [%{"tax_id" => ""}]}}
      end)

      expect(ManMock, :render_template, fn _id, _tamplate_data ->
        {:ok, "<html></html>"}
      end)

      conn
      |> post(cabinet_path(conn, :email_verification), %{email: email})
      |> json_response(200)
    end

    test "success", %{conn: conn} do
      email = "success-new-user@example.com"

      expect(MithrilMock, :search_user, fn %{email: ^email} ->
        {:ok, %{"data" => []}}
      end)

      expect(ManMock, :render_template, fn _id, %{verification_code: jwt} ->
        {:ok, claims} = decode_and_verify(jwt)
        assert Map.has_key?(claims, "email")
        assert "success-new-user@example.com" == claims["email"]
        assert 3600 == claims["exp"] - claims["iat"]

        {:ok, "<html></html>"}
      end)

      conn
      |> post(cabinet_path(conn, :email_verification), %{email: email})
      |> json_response(200)
    end
  end

  describe "validate email jwt" do
    test "success", %{conn: conn} do
      email = "info@example.com"
      {:ok, jwt, _} = encode_and_sign(:email, %{email: email}, token_type: "access")

      assert token =
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_path(conn, :email_validation))
               |> json_response(200)
               |> get_in(~w(data token))

      assert {:ok, claims} = decode_and_verify(token)
      assert Map.has_key?(claims, "email")
      assert email == claims["email"]
    end

    test "authorization header not send", %{conn: conn} do
      conn
      |> post(cabinet_path(conn, :email_validation))
      |> json_response(401)
    end

    test "invalid JWT type", %{conn: conn} do
      {:ok, jwt, _} = encode_and_sign(:email, %{email: "email@example.com"}, token_type: "refresh")

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> post(cabinet_path(conn, :email_validation))
      |> json_response(401)
    end

    test "invalid JWT claim", %{conn: conn} do
      jwt =
        "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJFSGVhbHRoIiwiZXhwIjoxNTIzMjgwNTYwLCJpYXQiOjE1MjA4" <>
          "NjEzNjAsImlzcyI6IkVIZWFsdGgiLCJqdGkiOiI5ZmZkNTQ2ZC1jOWUzLTRiMjgtYjJiMi00ZTRkYzI0YThkMTIiLCJuYmYiO" <>
          "jE1MjA4NjEzNTksIm5vIjoiZW1haWwiLCJzdWIiOiJ0ZXN0IiwidHlwIjoiYWNjZXNzIn0.PeEiFaq2KzzzhU5CN-QzjYZHYW" <>
          "BYrQmFA03H1nR-2K7_JzaHRBRZsMuwEc79Kp2EKul-JBrKYivmRsHLLuHdOA"

      assert {:ok, claims} = decode_and_verify(jwt)
      refute Map.has_key?(claims, "email")

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> post(cabinet_path(conn, :email_validation))
      |> json_response(401)
    end

    test "JWT expired", %{conn: conn} do
      jwt =
        "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJFSGVhbHRoIiwiZW1haWwiOiJlbWFpbEBleGFtcGxlLmNvbSIsImV4" <>
          "cCI6MTUyMDg2MzE3NCwiaWF0IjoxNTIwODYzMTE0LCJpc3MiOiJFSGVhbHRoIiwianRpIjoiZTM3MTAxYTAtYjc4Yy00YWE0LWI" <>
          "xMGUtYzhhMzBjMTAxM2E4IiwibmJmIjoxNTIwODYzMTEzLCJzdWIiOiJlbWFpbEBleGFtcGxlLmNvbSIsInR5cCI6ImFjY2Vzcy" <>
          "J9.CjvgesAPspb1I9jzAPNm48x_KSmbgLHvh8lvocPzFpRPbiUC7N6OWivfcsV4pEOo8vR19qD9Hy6gxiZ-Cx5kRg"

      assert {:error, :token_expired} = decode_and_verify(jwt)

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> post(cabinet_path(conn, :email_validation))
      |> json_response(401)
    end
  end
end
