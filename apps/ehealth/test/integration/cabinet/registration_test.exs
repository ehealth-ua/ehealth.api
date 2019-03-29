defmodule EHealth.Integration.Cabinet.RegistrationTest do
  use EHealth.Web.ConnCase, async: false

  import Mox
  import Core.Guardian

  alias Core.Cabinet.API, as: CabinetAPI
  alias Ecto.UUID

  setup :verify_on_exit!

  describe "Patient registration" do
    setup %{conn: conn} do
      email = "email@example.com"
      tax_id = "3126509816"

      expect(ManMock, :render_template, fn _id, template_data, _ ->
        assert Map.has_key?(template_data, :verification_code)
        {:ok, "<html></html>"}
      end)

      expect(SignatureMock, :decode_and_validate, 2, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Jason.decode!()
        assert Map.has_key?(content, "tax_id")

        data = %{
          "content" => content,
          "signatures" => [
            %{
              "is_valid" => true,
              "signer" => %{
                "edrpou" => content["tax_id"],
                "drfo" => content["tax_id"],
                "surname" => content["last_name"],
                "given_name" => "#{content["first_name"]} #{content["second_name"]}"
              },
              "validation_error_message" => ""
            }
          ]
        }

        {:ok, %{"data" => data}}
      end)

      expect_uaddresses_validate()

      expect(RPCWorkerMock, :run, fn _, _, :search_persons, [%{"tax_id" => "3126509816", "birth_date" => _}] ->
        {:ok, []}
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

      expect(MithrilMock, :create_global_user_role, fn _user_id, params, _headers ->
        Enum.each(~w(role_id)a, fn key ->
          assert Map.has_key?(params, key),
                 "Mithril.create_global_user_role requires param `#{key}` in `#{inspect(params)}` "
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

      {:ok, jwt} = get_jwt_token(email)

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
        signed_content: "../core/test/data/cabinet/patient.json" |> File.read!() |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

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
        signed_content: "../core/test/data/cabinet/patient.json" |> File.read!() |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      expect(OTPVerificationMock, :complete, fn _, _, _ ->
        {:ok, %{"data" => []}}
      end)

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

  describe "Validation" do
    setup %{conn: conn} do
      email = "email@example.com"
      tax_id = "3126509816"

      expect(ManMock, :render_template, fn _id, template_data, _ ->
        assert Map.has_key?(template_data, :verification_code)

        {:ok, "<html></html>"}
      end)

      expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Jason.decode!()
        assert Map.has_key?(content, "tax_id")

        data = %{
          "content" => content,
          "signatures" => [
            %{
              "is_valid" => true,
              "signer" => %{
                "edrpou" => content["tax_id"],
                "drfo" => content["tax_id"],
                "surname" => content["last_name"],
                "given_name" => "#{content["first_name"]} #{content["second_name"]}"
              },
              "validation_error_message" => ""
            }
          ]
        }

        {:ok, %{"data" => data}}
      end)

      expect(MithrilMock, :search_user, 2, fn %{email: ^email}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(OTPVerificationMock, :complete, fn _, _, _ ->
        {:ok, %{"data" => []}}
      end)

      %{conn: conn, email: email, tax_id: tax_id}
    end

    test "unzr does not match birthdate", %{conn: conn, email: email} do
      # 1. Send JWT to email for verification
      conn
      |> post(cabinet_auth_path(conn, :email_verification), %{email: email})
      |> json_response(200)

      # 2. Validate JWT from email and generate new JWT
      {:ok, jwt} = get_jwt_token(email)

      auth_token =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
        |> post(cabinet_auth_path(conn, :email_validation))
        |> json_response(200)
        |> get_in(~w(data token))

      params = %{
        otp: "1234",
        password: "pAs$w0rd",
        signed_content:
          "../core/test/data/cabinet/patient.json"
          |> File.read!()
          |> Jason.decode!()
          |> Map.put("unzr", "20180925-01234")
          |> Jason.encode!()
          |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      resp =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> auth_token)
        |> post(cabinet_auth_path(conn, :registration, params))
        |> json_response(422)

      assert [%{"entry" => "$.person.unzr", "rules" => [%{"description" => "Birthdate or unzr is not correct"}]}] =
               resp["error"]["invalid"]
    end

    test "unzr invalid format", %{conn: conn, email: email} do
      # 1. Send JWT to email for verification
      conn
      |> post(cabinet_auth_path(conn, :email_verification), %{email: email})
      |> json_response(200)

      {:ok, jwt} = get_jwt_token(email)

      auth_token =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
        |> post(cabinet_auth_path(conn, :email_validation))
        |> json_response(200)
        |> get_in(~w(data token))

      params = %{
        otp: "1234",
        password: "pAs$w0rd",
        signed_content:
          "../core/test/data/cabinet/patient.json"
          |> File.read!()
          |> Jason.decode!()
          |> Map.put("unzr", "0-1-2-3-4")
          |> Jason.encode!()
          |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      resp =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> auth_token)
        |> post(cabinet_auth_path(conn, :registration, params))
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.unzr",
                 "rules" => [%{"description" => "string does not match pattern \"^[0-9]{8}-[0-9]{5}$\""}]
               }
             ] = resp["error"]["invalid"]
    end

    test "invalid documents", %{conn: conn, email: email} do
      # 1. Send JWT to email for verification
      conn
      |> post(cabinet_auth_path(conn, :email_verification), %{email: email})
      |> json_response(200)

      {:ok, jwt} = get_jwt_token(email)

      auth_token =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
        |> post(cabinet_auth_path(conn, :email_validation))
        |> json_response(200)
        |> get_in(~w(data token))

      person =
        "../core/test/data/cabinet/patient.json"
        |> File.read!()
        |> Jason.decode!()

      person =
        Map.put(person, "documents", [
          %{
            "expiration_date" => "2017-02-28",
            "issued_at" => "2017-02-28",
            "issued_by" => "Рокитнянським РВ ГУ МВС Київської області",
            "number" => "012345678",
            "type" => "NATIONAL_ID"
          }
          | person["documents"]
        ])

      params = %{
        otp: "1234",
        password: "pAs$w0rd",
        signed_content:
          person
          |> Jason.encode!()
          |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      resp =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> auth_token)
        |> post(cabinet_auth_path(conn, :registration, params))
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.person.documents",
                 "rules" => [%{"description" => "Person can have only new passport NATIONAL_ID or old PASSPORT"}]
               }
             ] = resp["error"]["invalid"]
    end
  end

  defp get_jwt_token(email) do
    {:ok, jwt, _claims} =
      encode_and_sign(
        get_aud(:email_verification),
        %{email: email},
        token_type: "access",
        ttl: {Confex.fetch_env!(:core, CabinetAPI)[:jwt_ttl_email], "hours"}
      )

    {:ok, jwt}
  end
end
