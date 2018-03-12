defmodule Mithril.Web.RegistrationControllerTest do
  use EHealth.Web.ConnCase

  import Mox

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
        {:ok, claims} = EHealth.Guardian.decode_and_verify(jwt)
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
end
