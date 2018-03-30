defmodule Mithril.Web.RegistrationControllerTest do
  use EHealth.Web.ConnCase

  import Mox
  import EHealth.Guardian

  alias Ecto.UUID

  # For Mox lib. Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  defmodule SignatureExpect do
    defmacro __using__(_) do
      quote do
        expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
          content = signed_content |> Base.decode64!() |> Poison.decode!()

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
      end
    end
  end

  defmodule MithrilUserRoleExpect do
    defmacro __using__(_) do
      quote do
        expect(MithrilMock, :create_user_role, fn _user_id, params, _headers ->
          Enum.each(~w(role_id client_id)a, fn key ->
            assert Map.has_key?(params, key),
                   "Mithril.create_user_role requires param `#{key}` in `#{inspect(params)}` "
          end)

          data = %{
            "id" => UUID.generate(),
            "scope" => "cabinet:read"
          }

          {:ok, %{"data" => data}}
        end)

        expect(MithrilMock, :create_access_token, fn params, _headers ->
          Enum.each(~w(grant_type email password client_id scope)a, fn key ->
            assert Map.has_key?(params, key),
                   "Mithril.create_access_token requires param `#{key}` in `#{inspect(params)}`"
          end)

          assert "password" == params.grant_type
          assert "pAs$w0rd" == params.password

          data = %{
            "id" => UUID.generate(),
            "value" => "some_token_value"
          }

          {:ok, %{"data" => data}}
        end)
      end
    end
  end

  describe "send verification email" do
    test "invalid email", %{conn: conn} do
      assert "$.email" ==
               conn
               |> post(cabinet_auth_path(conn, :email_verification), %{email: "invalid"})
               |> json_response(422)
               |> get_in(~w(error invalid))
               |> hd()
               |> Map.get("entry")
    end

    test "no params", %{conn: conn} do
      assert "$.email" ==
               conn
               |> post(cabinet_auth_path(conn, :email_verification))
               |> json_response(422)
               |> get_in(~w(error invalid))
               |> hd()
               |> Map.get("entry")
    end

    test "user with passed email already exists", %{conn: conn} do
      email = "test@example.com"

      expect(MithrilMock, :search_user, fn %{email: "test@example.com"}, _headers ->
        {:ok, %{"data" => [%{"tax_id" => "23451234"}]}}
      end)

      assert "User with this email already exists" ==
               conn
               |> post(cabinet_auth_path(conn, :email_verification), %{email: email})
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "user with passed email already exists but tax_id is empty", %{conn: conn} do
      email = "success-new-user@example.com"

      expect(MithrilMock, :search_user, fn %{email: ^email}, _headers ->
        {:ok, %{"data" => [%{"tax_id" => ""}]}}
      end)

      expect(ManMock, :render_template, fn _id, _template_data ->
        {:ok, "<html></html>"}
      end)

      conn
      |> post(cabinet_auth_path(conn, :email_verification), %{email: email})
      |> json_response(200)
    end

    test "success", %{conn: conn} do
      email = "success-new-user@example.com"

      expect(MithrilMock, :search_user, fn %{email: ^email}, _headers ->
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
      |> post(cabinet_auth_path(conn, :email_verification), %{email: email})
      |> json_response(200)
    end
  end

  describe "validate email jwt" do
    test "success", %{conn: conn} do
      email = "info@example.com"
      {:ok, jwt, _} = encode_and_sign(get_aud(:email_verification), %{email: email}, token_type: "access")

      assert token =
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :email_validation))
               |> json_response(200)
               |> get_in(~w(data token))

      assert {:ok, claims} = decode_and_verify(token)
      assert Map.has_key?(claims, "email")
      assert email == claims["email"]
    end

    test "authorization header not send", %{conn: conn} do
      conn
      |> post(cabinet_auth_path(conn, :email_validation))
      |> json_response(401)
    end

    test "invalid JWT", %{conn: conn} do
      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer some_stadsf")
      |> post(cabinet_auth_path(conn, :email_validation))
      |> json_response(401)
    end

    test "invalid JWT type", %{conn: conn} do
      {:ok, jwt, _} =
        encode_and_sign(get_aud(:email_verification), %{email: "email@example.com"}, token_type: "refresh")

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> post(cabinet_auth_path(conn, :email_validation))
      |> json_response(401)
    end

    test "invalid JWT aud", %{conn: conn} do
      {:ok, jwt, _} = encode_and_sign(get_aud(:registration), %{email: "email@example.com"}, token_type: "access")

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> post(cabinet_auth_path(conn, :email_validation))
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
      |> post(cabinet_auth_path(conn, :email_validation))
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
      |> post(cabinet_auth_path(conn, :email_validation))
      |> json_response(401)
    end
  end

  describe "success patient registration" do
    setup %{conn: conn} do
      use SignatureExpect
      use MithrilUserRoleExpect

      params = %{
        otp: "1234",
        password: "pAs$w0rd",
        signed_person_data: "test/data/cabinet/patient.json" |> File.read!() |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      {:ok, jwt, _} = encode_and_sign(get_aud(:registration), %{email: "email@example.com"})
      %{conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer " <> jwt), params: params}
    end

    test "create new person and user", %{conn: conn, params: params} do
      expect(MPIMock, :search, fn %{"tax_id" => "3126509816", "birth_date" => _}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person!, fn params, headers ->
        refute Map.has_key?(params, "id")
        assert Map.has_key?(params, "patient_signed")
        assert Enum.member?(headers, {"x-consumer-id", "4261eacf-8008-4e62-899f-de1e2f7065f0"})
        {:ok, %{"data" => Map.put(params, "id", UUID.generate())}}
      end)

      expect(MithrilMock, :search_user, fn %{email: "email@example.com"}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MithrilMock, :create_user, fn params, _headers ->
        Enum.each(~w(otp tax_id email password 2fa_enable factor), fn key ->
          assert Map.has_key?(params, key)
        end)

        data =
          params
          |> Map.put("id", UUID.generate())
          |> Map.delete("password")

        {:ok, %{"data" => data}}
      end)

      conn
      |> post(cabinet_auth_path(conn, :registration, params))
      |> json_response(201)

      # |> assert_show_response_schema("cabinet")
    end

    test "create new user and update MPI person", %{conn: conn, params: params} do
      person_id = UUID.generate()

      expect(MPIMock, :search, fn %{"tax_id" => "3126509816", "birth_date" => _}, _headers ->
        {:ok, %{"data" => [%{"id" => person_id}]}}
      end)

      expect(MPIMock, :update_person, fn ^person_id, params, _headers ->
        assert Map.has_key?(params, "patient_signed")
        {:ok, %{"data" => Map.put(params, "id", person_id)}}
      end)

      expect(MithrilMock, :search_user, fn %{email: "email@example.com"}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MithrilMock, :create_user, fn params, _headers ->
        assert Map.has_key?(params, "tax_id")
        assert Map.has_key?(params, "email")
        assert Map.has_key?(params, "password")

        data =
          params
          |> Map.put("id", UUID.generate())
          |> Map.delete("password")

        {:ok, %{"data" => data}}
      end)

      conn
      |> post(cabinet_auth_path(conn, :registration, params))
      |> json_response(201)

      # |> assert_show_response_schema("cabinet")
    end

    test "update user and create new MPI person", %{conn: conn, params: params} do
      expect(MPIMock, :search, fn %{"tax_id" => "3126509816", "birth_date" => _}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person!, fn params, _headers ->
        refute Map.has_key?(params, "id")
        assert Map.has_key?(params, "patient_signed")
        {:ok, %{"data" => Map.put(params, "id", UUID.generate())}}
      end)

      user_id = UUID.generate()

      expect(MithrilMock, :search_user, fn %{email: "email@example.com"}, _headers ->
        {:ok, %{"data" => [%{"id" => user_id, "tax_id" => ""}]}}
      end)

      expect(MithrilMock, :change_user, fn ^user_id, params, _headers ->
        assert Map.has_key?(params, "tax_id")
        assert Map.has_key?(params, "email")
        assert Map.has_key?(params, "password")

        data =
          params
          |> Map.put("id", user_id)
          |> Map.delete("password")

        {:ok, %{"data" => data}}
      end)

      conn
      |> post(cabinet_auth_path(conn, :registration, params))
      |> json_response(201)

      # |> assert_show_response_schema("cabinet")
    end

    test "update user and update MPI person", %{conn: conn, params: params} do
      person_id = UUID.generate()

      expect(MPIMock, :search, fn %{"tax_id" => "3126509816", "birth_date" => _}, _headers ->
        {:ok, %{"data" => [%{"id" => person_id}]}}
      end)

      expect(MPIMock, :update_person, fn ^person_id, params, headers ->
        assert Map.has_key?(params, "patient_signed")
        assert Enum.member?(headers, {"x-consumer-id", "4261eacf-8008-4e62-899f-de1e2f7065f0"})
        {:ok, %{"data" => Map.put(params, "id", person_id)}}
      end)

      user_id = UUID.generate()

      expect(MithrilMock, :search_user, fn %{email: "email@example.com"}, _headers ->
        {:ok, %{"data" => [%{"id" => user_id, "tax_id" => ""}]}}
      end)

      expect(MithrilMock, :change_user, fn ^user_id, params, _headers ->
        assert Map.has_key?(params, "tax_id")
        assert Map.has_key?(params, "email")
        assert Map.has_key?(params, "password")

        data =
          params
          |> Map.put("id", user_id)
          |> Map.delete("password")

        {:ok, %{"data" => data}}
      end)

      conn
      |> post(cabinet_auth_path(conn, :registration, params))
      |> json_response(201)

      # |> assert_show_response_schema("cabinet")
    end
  end

  describe "invalid patient registration" do
    setup %{conn: conn} do
      params = %{
        otp: "1234",
        password: "pAs$w0rd",
        signed_person_data: "test/data/cabinet/patient.json" |> File.read!() |> Base.encode64(),
        signed_content_encoding: "base64"
      }

      {:ok, jwt, _} = encode_and_sign(get_aud(:registration), %{email: "email@example.com"})

      %{conn: conn, params: params, jwt: jwt}
    end

    test "user exists with tax_id", %{conn: conn, params: params, jwt: jwt} do
      use SignatureExpect

      expect(MPIMock, :search, fn %{"tax_id" => "3126509816", "birth_date" => _}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person!, fn params, headers ->
        refute Map.has_key?(params, "id")
        assert Map.has_key?(params, "patient_signed")
        assert Enum.member?(headers, {"x-consumer-id", "4261eacf-8008-4e62-899f-de1e2f7065f0"})
        {:ok, %{"data" => Map.put(params, "id", UUID.generate())}}
      end)

      expect(MithrilMock, :search_user, fn %{email: "email@example.com"}, _headers ->
        {:ok, %{"data" => [%{"tax_id" => "1234567890"}]}}
      end)

      assert "User with this tax_id already exists" ==
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration), params)
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "different last_name in signed content and DS", %{conn: conn, params: params, jwt: jwt} do
      expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Poison.decode!()

        data = %{
          "signer" => %{
            "drfo" => content["tax_id"],
            "surname" => "Шевченко",
            "given_name" => content["first_name"] <> " " <> content["second_name"]
          },
          "is_valid" => true,
          "content" => content
        }

        {:ok, %{"data" => data}}
      end)

      assert "Input last_name doesn't match name from DS" ==
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration), params)
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "no surname in Signer from DS", %{conn: conn, params: params, jwt: jwt} do
      expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Poison.decode!()

        data = %{
          "signer" => %{
            "drfo" => content["tax_id"],
            "given_name" => content["first_name"] <> " " <> content["second_name"]
          },
          "is_valid" => true,
          "content" => content
        }

        {:ok, %{"data" => data}}
      end)

      assert "Input last_name doesn't match name from DS" ==
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration), params)
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "different first_name in signed content and DS", %{conn: conn, params: params, jwt: jwt} do
      expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Poison.decode!()

        data = %{
          "signer" => %{
            "drfo" => content["tax_id"],
            "surname" => content["last_name"],
            "given_name" => "Сара Коннор"
          },
          "is_valid" => true,
          "content" => content
        }

        {:ok, %{"data" => data}}
      end)

      assert "Input first_name doesn't match name from DS" ==
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration), params)
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "no given_name in Signer from DS", %{conn: conn, params: params, jwt: jwt} do
      expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Poison.decode!()

        data = %{
          "signer" => %{
            "drfo" => content["tax_id"],
            "surname" => content["last_name"]
          },
          "is_valid" => true,
          "content" => content
        }

        {:ok, %{"data" => data}}
      end)

      assert "Input first_name doesn't match name from DS" ==
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration), params)
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "different email in signed content and JWT", %{conn: conn, params: params} do
      use SignatureExpect
      {:ok, jwt, _} = encode_and_sign(get_aud(:registration), %{email: "not-matched@example.com"})

      assert "Email in signed content is incorrect" ==
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration), params)
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "different tax_id in signed content and digital signature", %{conn: conn, params: params, jwt: jwt} do
      expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Poison.decode!()
        assert Map.has_key?(content, "tax_id")

        data = %{
          "signer" => %{
            "drfo" => "002233445566"
          },
          "signed_content" => signed_content,
          "is_valid" => true,
          "content" => content
        }

        {:ok, %{"data" => data}}
      end)

      assert "Registration person and person that sign should be the same" ==
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration), params)
               |> json_response(409)
               |> get_in(~w(error message))
    end

    test "invalid signed_person_data format", %{conn: conn, params: params, jwt: jwt} do
      params = Map.put(params, :signed_person_data, "some string")

      assert [err] =
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration, params))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.signed_person_data" == err["entry"]
    end

    test "JWT not set", %{conn: conn, params: params} do
      conn
      |> post(cabinet_auth_path(conn, :registration, params))
      |> json_response(401)
    end

    test "invalid JWT aud", %{conn: conn} do
      {:ok, jwt, _} = encode_and_sign(get_aud(:email_verification), %{email: "email@example.com"}, token_type: "access")

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> post(cabinet_auth_path(conn, :registration))
      |> json_response(401)
    end

    test "invalid person data", %{conn: conn, params: params, jwt: jwt} do
      use SignatureExpect

      signed_person_data =
        %{
          "birth_date" => "today",
          "tax_id" => "1112223344",
          "email" => "email@example.com"
        }
        |> Poison.encode!()
        |> Base.encode64()

      err =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
        |> post(cabinet_auth_path(conn, :registration, Map.put(params, :signed_person_data, signed_person_data)))
        |> json_response(422)
        |> get_in(~w(error invalid))

      assert "$.birth_date" == hd(err)["entry"]
    end

    test "422 response code on MPI", %{conn: conn, params: params, jwt: jwt} do
      use SignatureExpect

      expect(MPIMock, :search, fn %{"tax_id" => "3126509816", "birth_date" => _}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person!, fn _params, _headers ->
        {:error,
         %{
           "error" => %{
             "invalid" => [
               %{
                 "entry" => "$.email",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "invalid email format",
                     "params" => [],
                     "rule" => "format"
                   }
                 ]
               }
             ],
             "message" => "Validation failed.",
             "type" => "validation_failed"
           },
           "meta" => %{
             "code" => 422
           }
         }}
      end)

      assert [err] =
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration, params))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.email" == err["entry"]
    end

    test "invalid OTP for user factor", %{conn: conn, params: params, jwt: jwt} do
      use SignatureExpect

      expect(MPIMock, :search, fn %{"tax_id" => "3126509816", "birth_date" => _}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person!, fn params, _headers ->
        refute Map.has_key?(params, "id")
        assert Map.has_key?(params, "patient_signed")
        {:ok, %{"data" => Map.put(params, "id", UUID.generate())}}
      end)

      expect(MithrilMock, :search_user, fn %{email: "email@example.com"}, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MithrilMock, :create_user, fn _params, _headers ->
        {:error,
         %{
           "error" => %{
             "invalid" => [
               %{
                 "entry" => "$.otp",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "invalid code",
                     "params" => [],
                     "rule" => "invalid"
                   }
                 ]
               }
             ],
             "message" => "Validation failed.",
             "type" => "validation_failed"
           },
           "meta" => %{
             "code" => 422
           }
         }}
      end)

      assert [err] =
               conn
               |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
               |> post(cabinet_auth_path(conn, :registration, params))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.otp" == err["entry"]
    end
  end

  describe "search user" do
    setup %{conn: conn} do
      {:ok, jwt, _} = encode_and_sign(get_aud(:registration), %{email: "email@example.com"})
      %{conn: conn, jwt: jwt}
    end

    test "jwt not set", %{conn: conn} do
      conn
      |> get(cabinet_persons_path(conn, :search_user), %{tax_id: "1234567890"})
      |> json_response(401)
    end

    test "by tax_id found", %{conn: conn, jwt: jwt} do
      expect(MithrilMock, :search_user, fn %{tax_id: "1234567890"}, _headers ->
        {:ok, %{"data" => []}}
      end)

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> get(cabinet_persons_path(conn, :search_user, %{tax_id: "1234567890"}))
      |> json_response(200)
    end

    test "by tax_id not found", %{conn: conn, jwt: jwt} do
      expect(MithrilMock, :search_user, fn %{tax_id: "1234567890"}, _headers ->
        {:ok, %{"data" => [%{"id" => 1}]}}
      end)

      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> get(cabinet_persons_path(conn, :search_user), %{tax_id: "1234567890"})
      |> json_response(409)
    end

    test "tax_id not set", %{conn: conn, jwt: jwt} do
      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
      |> get(cabinet_persons_path(conn, :search_user), %{tax_id_invalid: "1234567890"})
      |> json_response(422)
    end
  end
end
