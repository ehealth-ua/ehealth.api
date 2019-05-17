defmodule EHealth.Web.UserControllerTest do
  @moduledoc false
  use EHealth.Web.ConnCase
  use Bamboo.Test
  import Mox
  alias Core.Users.CredentialsRecoveryRequest
  alias Core.Repo
  alias Ecto.UUID

  setup :verify_on_exit!

  @test_user_id UUID.generate()

  @create_attrs %{
    "user_id" => @test_user_id,
    "email" => "bob@example.com",
    "is_active" => true
  }

  @user_attrs %{
    "email" => "bob@example.com",
    "settings" => %{},
    "priv_settings" => %{},
    "id" => @test_user_id,
    "created_at" => "2017-04-20T19:14:13Z",
    "updated_at" => "2017-04-20T19:14:13Z"
  }

  describe "create credentials recovery request" do
    test "submits recovery email when user exists", %{conn: conn} do
      expect(MithrilMock, :search_user, fn _, _ ->
        {:ok, %{"data" => [@user_attrs]}}
      end)

      expect(RPCWorkerMock, :run, fn "man_api", Man.Rpc, :render_template, [5, data] ->
        printout_form =
          "<html><body>Email for credentials recovery " <>
            "request ##{data["credentials_recovery_request_id"]}?client_id=#{data["client_id"]}&redirect_uri=#{
              data["redirect_uri"]
            }</body></html>"

        {:ok, printout_form}
      end)

      attrs = %{
        "credentials_recovery_request" => %{
          "email" => "bob@example.com",
          "client_id" => UUID.generate(),
          "redirect_uri" => "blabla"
        }
      }

      conn = post(conn, user_path(conn, :create_credentials_recovery_request), attrs)
      assert %{"is_active" => true, "expires_at" => _} = json_response(conn, 201)["data"]
      assert 1 == length(Repo.all(CredentialsRecoveryRequest))
      assert_delivered_with(to: [nil: "bob@example.com"])
    end

    test "returns validation error when user not found", %{conn: conn} do
      expect(MithrilMock, :search_user, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      attrs = %{
        "credentials_recovery_request" => %{
          "email" => "mike@example.com",
          "client_id" => UUID.generate(),
          "redirect_uri" => "blabla"
        }
      }

      conn = post(conn, user_path(conn, :create_credentials_recovery_request), attrs)

      assert [%{"entry" => "$.email", "rules" => [%{"description" => "does not exist", "rule" => "existence"}]}] =
               json_response(conn, 422)["error"]["invalid"]
    end

    test "returns validation error when email is not set", %{conn: conn} do
      attrs = %{"credentials_recovery_request" => %{}}
      conn = post(conn, user_path(conn, :create_credentials_recovery_request), attrs)

      assert [%{"entry" => "$.email", "rules" => [%{"rule" => "required"}]}] =
               json_response(conn, 422)["error"]["invalid"]
    end

    test "returns validation error when client_id or/and redirect_uri is not set", %{conn: conn} do
      attrs = %{"credentials_recovery_request" => %{"email" => "bob@example.com"}}
      conn = post(conn, user_path(conn, :create_credentials_recovery_request), attrs)

      assert [
               %{
                 "entry" => "$.client_id",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "required property client_id was not present",
                     "rule" => "required"
                   }
                 ]
               },
               %{
                 "entry" => "$.redirect_uri",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "required property redirect_uri was not present",
                     "rule" => "required"
                   }
                 ]
               }
             ] = json_response(conn, 422)["error"]["invalid"]
    end

    test "returns validation error when client_id is invalid", %{conn: conn} do
      attrs = %{
        "credentials_recovery_request" => %{
          "email" => "mike@example.com",
          "client_id" => "test",
          "redirect_uri" => "blabla"
        }
      }

      conn = post(conn, user_path(conn, :create_credentials_recovery_request), attrs)

      assert [%{"entry" => "$.client_id", "rules" => [%{"rule" => "format"}]}] =
               json_response(conn, 422)["error"]["invalid"]
    end
  end

  describe "reset password" do
    test "changes user password with valid request id", %{conn: conn} do
      expect(MithrilMock, :change_user, fn user_id, params, _headers ->
        data =
          params
          |> Map.put("id", user_id)
          |> Map.delete("password")

        {:ok, %{"data" => Map.merge(@user_attrs, data)}}
      end)

      %{id: credentials_recovery_request_id} = credentials_recovery_request_fixture(@create_attrs)
      reset_attrs = %{"user" => %{"password" => "new_but_not_a_secret"}}
      conn = patch(conn, user_path(conn, :reset_password, credentials_recovery_request_id), reset_attrs)

      assert %{"email" => "bob@example.com", "id" => @test_user_id, "settings" => %{}} ==
               json_response(conn, 200)["data"]

      [%{is_active: false}] = Repo.all(CredentialsRecoveryRequest)
    end

    test "returns not found error when request id does not exist", %{conn: conn} do
      reset_attrs = %{"user" => %{"password" => "new_but_not_a_secret"}}
      conn = patch(conn, user_path(conn, :reset_password, Ecto.UUID.generate()), reset_attrs)
      assert json_response(conn, 404)
    end

    test "returns validation error when request is expired", %{conn: conn} do
      %{id: id} = credentials_recovery_request_fixture(@create_attrs)

      old_ttl = Application.get_env(:core, :credentials_recovery_request_ttl)

      on_exit(fn ->
        Application.put_env(:core, :credentials_recovery_request_ttl, old_ttl)
      end)

      Application.put_env(:core, :credentials_recovery_request_ttl, 0)
      reset_attrs = %{"user" => %{"password" => "new_but_not_a_secret"}}
      conn = patch(conn, user_path(conn, :reset_password, id), reset_attrs)

      assert [%{"entry" => "$.expires_at", "rules" => [%{"rule" => "expiration"}]}] =
               json_response(conn, 422)["error"]["invalid"]
    end

    test "returns not found error when request is not active", %{conn: conn} do
      %{id: id} = credentials_recovery_request_fixture(Map.put(@create_attrs, "is_active", false))
      reset_attrs = %{"user" => %{"password" => "new_but_not_a_secret"}}
      conn = patch(conn, user_path(conn, :reset_password, id), reset_attrs)
      assert json_response(conn, 404)
    end

    test "returns validation error when new password is not set", %{conn: conn} do
      %{id: credentials_recovery_request_id} = credentials_recovery_request_fixture(@create_attrs)
      reset_attrs = %{"user" => %{}}
      conn = patch(conn, user_path(conn, :reset_password, credentials_recovery_request_id), reset_attrs)

      assert [%{"entry" => "$.password", "rules" => [%{"rule" => "required"}]}] =
               json_response(conn, 422)["error"]["invalid"]
    end
  end

  defp credentials_recovery_request_fixture(attrs) do
    Repo.insert!(%CredentialsRecoveryRequest{
      user_id: Map.get(attrs, "user_id"),
      email: Map.get(attrs, "email"),
      is_active: Map.get(attrs, "is_active", true)
    })
  end
end
