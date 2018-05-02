defmodule EHealth.Integration.Cabinet.RegistrationTest do
  use EHealth.Web.ConnCase

  import Mox
  import EHealth.Guardian

  alias Ecto.UUID

  setup :verify_on_exit!

  describe "Patient registration" do
    setup %{conn: conn} do
      :ets.new(:jwt, [:named_table])

      email = "email@example.com"
      tax_id = "3126509816"

      expect(ManMock, :render_template, fn _id, template_data ->
        assert Map.has_key?(template_data, :verification_code)
        :ets.insert(:jwt, {"jwt", template_data.verification_code})
        {:ok, "<html></html>"}
      end)

      expect(SignatureMock, :decode_and_validate, 2, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Poison.decode!()
        assert Map.has_key?(content, "tax_id")

        data = %{
          "signer" => %{
            "edrpou" => content["tax_id"],
            "drfo" => content["tax_id"],
            "surname" => content["last_name"],
            "given_name" => "#{content["first_name"]} #{content["second_name"]}"
          },
          "signed_content" => signed_content,
          "is_valid" => true,
          "content" => content
        }

        {:ok, %{"data" => data}}
      end)

      expect(MPIMock, :search, fn params, _headers ->
        assert Map.has_key?(params, "tax_id")
        assert Map.has_key?(params, "birth_date")
        assert tax_id == params["tax_id"]

        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person!, fn params, _headers ->
        refute Map.has_key?(params, "id")
        {:ok, %{"data" => Map.put(params, "id", UUID.generate())}}
      end)

      expect(MithrilMock, :search_user, 3, fn %{email: ^email}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MithrilMock, :search_user, fn %{tax_id: ^tax_id}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MithrilMock, :search_user, fn %{email: ^email}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MithrilMock, :create_user, fn params, _headers ->
        Enum.each(~w(otp tax_id email password), fn key ->
          assert Map.has_key?(params, key)
        end)

        assert "1234" == params["otp"]

        data =
          params
          |> Map.put("id", UUID.generate())
          |> Map.delete("password")

        {:ok, %{"data" => data}}
      end)

      expect(MithrilMock, :create_user_role, fn _user_id, params, _headers ->
        Enum.each(~w(role_id client_id)a, fn key ->
          assert Map.has_key?(params, key), "Mithril.create_user_role requires param `#{key}` in `#{inspect(params)}` "
        end)

        data = %{
          "id" => UUID.generate(),
          "scope" => "cabinet:read"
        }

        {:ok, %{"data" => data}}
      end)

      expect(MithrilMock, :create_access_token, fn _user_id, params, _headers ->
        Enum.each(~w(client_id scope)a, fn key ->
          assert Map.has_key?(params, key),
                 "Mithril.create_access_token requires param `#{key}` in `#{inspect(params)}`"
        end)

        assert "app:authorize" == params.scope

        data = %{
          "id" => UUID.generate(),
          "value" => "some_token_value"
        }

        {:ok, %{"data" => data}}
      end)

      %{conn: conn, email: email}
    end

    test "happy path", %{conn: conn, email: email} do
      # 1. Send JWT to email for verification
      conn
      |> post(cabinet_auth_path(conn, :email_verification), %{email: email})
      |> json_response(200)

      # 2. Validate JWT from email and generate new JWT

      [{"jwt", jwt}] = :ets.lookup(:jwt, "jwt")

      auth_token =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
        |> post(cabinet_auth_path(conn, :email_validation))
        |> json_response(200)
        |> get_in(~w(data token))

      assert {:ok, claims} = decode_and_verify(auth_token)
      assert Map.has_key?(claims, "email")
      assert email == claims["email"]

      # 3. Check that user with tax_id from signet content not exist

      params = %{
        signed_content: "test/data/cabinet/patient.json" |> File.read!() |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> auth_token)
      |> post(cabinet_auth_path(conn, :search_user, params))
      |> json_response(200)

      # 4. Send OTP for phone verification
      # This step implemented on Mithril.

      # 5. Register patient

      params = %{
        otp: "1234",
        password: "pAs$w0rd",
        signed_content: "test/data/cabinet/patient.json" |> File.read!() |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      patient =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> auth_token)
        |> post(cabinet_auth_path(conn, :registration, params))
        |> json_response(201)
        |> Map.get("data")

      assert Map.has_key?(patient, "access_token")
      assert "some_token_value" == patient["access_token"]
    end
  end
end
