defmodule EHealth.Integration.DeclarationRequestCreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Mox
  import Core.Expectations.Man

  alias Core.DeclarationRequests
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Repo
  alias Core.Utils.NumberGenerator
  alias Ecto.UUID

  setup :verify_on_exit!

  defp gen_sequence_number do
    expect(DeclarationRequestsCreatorMock, :sql_get_sequence_number, fn ->
      {:ok, %Postgrex.Result{rows: [[Enum.random(1_000_000..2_000_000)]]}}
    end)
  end

  describe "Happy paths v1" do
    setup %{conn: conn} do
      insert(:prm, :global_parameter, %{parameter: "adult_age", value: "18"})
      insert(:prm, :global_parameter, %{parameter: "declaration_term", value: "40"})
      insert(:prm, :global_parameter, %{parameter: "declaration_term_unit", value: "YEARS"})

      insert_dictionaries()

      legal_entity = insert(:prm, :legal_entity, id: "8799e3b6-34e7-4798-ba70-d897235d2b6d")
      insert(:prm, :medical_service_provider, legal_entity: legal_entity)
      party = insert(:prm, :party, id: "ac6ca796-9cc8-4a8f-96f8-016dd52daac6")
      insert(:prm, :party_user, party: party)
      division = insert(:prm, :division, id: "51f56b0e-0223-49c1-9b5f-b07e09ba40f1", legal_entity: legal_entity)

      doctor = Map.put(doctor(), "specialities", [%{speciality: "PEDIATRICIAN"}])

      insert(
        :prm,
        :employee,
        id: "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
        division: division,
        party: party,
        legal_entity: legal_entity,
        additional_info: doctor
      )

      {:ok, %{conn: conn}}
    end

    test "declaration request `mpi_id` is not saved for children", %{conn: conn} do
      gen_sequence_number()
      template()

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      age = 13
      person_birth_date = Timex.shift(Timex.today(), years: -age) |> to_string()

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["declaration_request", "person", "birth_date"], person_birth_date)
        |> pop_in(["declaration_request", "person", "tax_id"])
        |> elem(1)

      uaddresses_mock_expect()

      assert %{"id" => declaration_request_id} =
               conn
               |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
               |> put_req_header(
                 "x-consumer-metadata",
                 Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"})
               )
               |> post(declaration_request_path(conn, :create), declaration_request_params)
               |> json_response(200)
               |> Map.get("data")

      assert nil == Repo.get(DeclarationRequest, declaration_request_id).mpi_id
    end

    test "declaration request doctor speciality doesn't match patient's age", %{conn: conn} do
      gen_sequence_number()

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      age = 17
      person_birth_date = Timex.shift(Timex.today(), years: -age) |> to_string()
      speciality = %{"speciality" => "THERAPIST"}

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          speciality: speciality
        )

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["declaration_request", "person", "birth_date"], person_birth_date)
        |> put_in(["declaration_request", "employee_id"], employee_id)

      uaddresses_mock_expect()

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)
        |> json_response(422)

      assert [error] = resp["error"]["invalid"]
      assert "Doctor speciality doesn't match patient's age" == error["rules"] |> List.first() |> Map.get("description")
    end

    test "declaration request doctor speciality doesn't match patient's adult age", %{conn: conn} do
      gen_sequence_number()

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      age = 18
      person_birth_date = Timex.shift(Timex.today(), years: -age) |> to_string()
      speciality = %{"speciality" => "PEDIATRICIAN"}

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          speciality: speciality
        )

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["declaration_request", "person", "birth_date"], person_birth_date)
        |> put_in(["declaration_request", "employee_id"], employee_id)

      uaddresses_mock_expect()

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)
        |> json_response(422)

      assert [error] = resp["error"]["invalid"]
      assert "Doctor speciality doesn't match patient's age" == error["rules"] |> List.first() |> Map.get("description")
    end

    test "declaration request without required confidant person for child", %{conn: conn} do
      age = 13
      person_birth_date = Timex.shift(Timex.today(), years: -age) |> to_string()

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["declaration_request", "person", "birth_date"], person_birth_date)
        |> pop_in(["declaration_request", "person", "confidant_person"])
        |> elem(1)

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)
        |> json_response(422)

      assert [error] = resp["error"]["invalid"]
      assert "Confidant person is mandatory for children" == error["rules"] |> List.first() |> Map.get("description")
    end

    test "declaration request with non verified phone for OTP auth", %{conn: conn} do
      gen_sequence_number()

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:error, nil}
      end)

      auth_methods = [%{"type" => "OTP", "phone_number" => "+380508887404"}]

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(~W(declaration_request person authentication_methods), auth_methods)

      uaddresses_mock_expect()

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)

      resp = json_response(conn, 422)
      assert [error] = resp["error"]["invalid"]
      assert "The phone number is not verified." == error["rules"] |> List.first() |> Map.get("description")
    end

    test "secret is too long", %{conn: conn} do
      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(~W(declaration_request person secret), "a very long secret value")

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.declaration_request.person.secret",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "expected value to have a maximum length of 20 but was 24",
                       "params" => %{"max" => 20},
                       "rule" => "length"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "declaration request sequence is not works", %{conn: conn} do
      expect(DeclarationRequestsCreatorMock, :sql_get_sequence_number, fn ->
        {:error, [:any]}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()

      declaration_request_params =
        put_in(
          declaration_request_params,
          ~W(declaration_request person),
          Map.delete(declaration_request_params["declaration_request"]["person"], "phones")
        )

      uaddresses_mock_expect()

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)
        |> json_response(422)

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.sequence",
                     "rules" => [
                       %{
                         "description" => "declaration_request sequence doesn't return a number"
                       }
                     ]
                   }
                 ]
               }
             } = resp
    end

    test "declaration request without person.phone", %{conn: conn} do
      gen_sequence_number()
      template()

      expect(MPIMock, :search, fn params, _ ->
        {:ok,
         %{
           "data" => [
             params
             |> Map.put("id", "b5350f79-f2ca-408f-b15d-1ae0a8cc861c")
             |> Map.put("authentication_methods", [
               %{"type" => "OTP", "phone_number" => "+380508887700"}
             ])
           ]
         }}
      end)

      expect(OTPVerificationMock, :initialize, fn _number, _headers ->
        {:ok, %{}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()

      declaration_request_params =
        put_in(
          declaration_request_params,
          ~W(declaration_request person),
          Map.delete(declaration_request_params["declaration_request"]["person"], "phones")
        )

      uaddresses_mock_expect()

      conn
      |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
      |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
      |> post(declaration_request_path(conn, :create), declaration_request_params)
      |> json_response(200)
    end

    test "declaration request without required phone number", %{conn: conn} do
      gen_sequence_number()

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(~W(declaration_request person authentication_methods), [%{"type" => "OTP"}])

      uaddresses_mock_expect()

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)

      resp = json_response(conn, 422)
      assert [error] = resp["error"]["invalid"]

      assert "required property phone_number was not present" ==
               error["rules"] |> List.first() |> Map.get("description")
    end

    test "declaration request with two similar phone numbers type results in validation error", %{conn: conn} do
      phones = [%{"type" => "MOBILE", "number" => "+380508887700"}, %{"type" => "MOBILE", "number" => "+380508887700"}]

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(~W(declaration_request person phones), phones)

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)

      resp = json_response(conn, 422)
      assert [error] = resp["error"]["invalid"]

      assert %{"description" => "No duplicate values.", "params" => ["MOBILE"], "rule" => "invalid"} ==
               error["rules"] |> List.first()
    end

    test "declaration request is created with 'OTP' verification", %{conn: conn} do
      gen_sequence_number()
      role_id = UUID.generate()

      expect(MPIMock, :search, fn params, _ ->
        {:ok,
         %{
           "data" => [
             params
             |> Map.put("id", "b5350f79-f2ca-408f-b15d-1ae0a8cc861c")
             |> Map.put("authentication_methods", [
               %{"type" => "OTP", "phone_number" => "+380508887700"}
             ])
           ]
         }}
      end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(OTPVerificationMock, :initialize, fn _number, _headers ->
        {:ok, %{}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "99bc78ba577a95a11f1a344d4d2ae55f2f857b98"}}}
      end)

      params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()

      tax_id = get_in(params, ~w(declaration_request person tax_id))
      html_template("<html><body>Printout form for declaration request. tax_id = #{tax_id}</body></html>")

      uaddresses_mock_expect()

      tax_id = get_in(params["declaration_request"], ["person", "tax_id"])
      employee_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"
      legal_entity_id = "8799e3b6-34e7-4798-ba70-d897235d2b6d"

      d1 =
        insert(
          :il,
          :declaration_request,
          data: %{
            person: %{
              tax_id: tax_id
            },
            employee: %{
              id: employee_id
            },
            legal_entity: %{
              id: legal_entity_id
            }
          },
          status: "NEW"
        )

      d2 =
        insert(
          :il,
          :declaration_request,
          data: %{
            person: %{
              tax_id: tax_id
            },
            employee: %{
              id: employee_id
            },
            legal_entity: %{
              id: legal_entity_id
            }
          },
          status: "APPROVED"
        )

      resp =
        conn
        |> put_req_header("x-consumer-id", employee_id)
        |> put_client_id_header(legal_entity_id)
        |> post(declaration_request_path(conn, :create), params)
        |> json_response(200)

      id = resp["data"]["id"]

      assert_show_response_schema(resp, "declaration_request")

      assert to_string(Date.utc_today()) == resp["data"]["start_date"]
      assert {:ok, _} = Date.from_iso8601(resp["data"]["end_date"])
      assert "99bc78ba577a95a11f1a344d4d2ae55f2f857b98" == resp["data"]["seed"]

      declaration_request = DeclarationRequests.get_by_id!(id)
      assert declaration_request.data["legal_entity"]["id"]
      assert declaration_request.data["division"]["id"]
      assert declaration_request.data["employee"]["id"]
      # TODO: turn this into DB checks
      #
      # assert "NEW" = resp["status"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["updated_by"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["inserted_by"]
      # assert %{"number" => "+380508887700", "type" => "OTP"} = resp["authentication_method_current"]
      tax_id = resp["data"]["person"]["tax_id"]

      assert "<html><body>Printout form for declaration request. tax_id = #{tax_id}</body></html>" ==
               resp["data"]["content"]

      refute Map.has_key?(resp["urgent"], "documents")
      assert "CANCELLED" = Repo.get(DeclarationRequest, d1.id).status
      assert "CANCELLED" = Repo.get(DeclarationRequest, d2.id).status
    end

    test "declaration request is created with 'Offline' verification", %{conn: conn} do
      gen_sequence_number()

      expect(MediaStorageMock, :create_signed_url, 4, fn _, _, resource_name, resource_id, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://a.link.for/#{resource_id}/#{resource_name}"}}}
      end)

      expect(MPIMock, :search, fn params, _ ->
        {:ok,
         %{
           "data" => [
             params
             |> Map.put("id", "b5350f79-f2ca-408f-b15d-1ae0a8cc861c")
             |> Map.put("authentication_methods", [
               %{"type" => "NA"}
             ])
           ]
         }}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(~W(declaration_request person first_name), "Тест")
        |> put_in(~W(declaration_request person authentication_methods), [%{"type" => "OFFLINE"}])

      tax_id = get_in(declaration_request_params, ~w(declaration_request person tax_id))
      html_template("<html><body>Printout form for declaration request. tax_id = #{tax_id}</body></html>")
      uaddresses_mock_expect()

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), Jason.encode!(declaration_request_params))
        |> json_response(200)

      assert_show_response_schema(resp, "declaration_request")
      assert to_string(Date.utc_today()) == resp["data"]["start_date"]
      assert {:ok, _} = Date.from_iso8601(resp["data"]["end_date"])
      # TODO: turn this into DB checks
      #
      # assert "NEW" = resp["data"]["status"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["updated_by"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["inserted_by"]
      # assert %{"number" => "+380508887700", "type" => "OFFLINE"} = resp["data"]["authentication_method_current"]
      tax_id = resp["data"]["person"]["tax_id"]

      assert "<html><body>Printout form for declaration request. tax_id = #{tax_id}</body></html>" ==
               resp["data"]["content"]

      assert [
               %{
                 "type" => "person.BIRTH_CERTIFICATE",
                 "url" => "http://a.link.for/#{resp["data"]["id"]}/declaration_request_person.BIRTH_CERTIFICATE.jpeg"
               },
               %{
                 "type" => "person.PASSPORT",
                 "url" => "http://a.link.for/#{resp["data"]["id"]}/declaration_request_person.PASSPORT.jpeg"
               },
               %{
                 "type" => "person.tax_id",
                 "url" => "http://a.link.for/#{resp["data"]["id"]}/declaration_request_person.tax_id.jpeg"
               },
               %{
                 "type" => "confidant_person.0.PRIMARY.RELATIONSHIP.COURT_DECISION",
                 "url" =>
                   "http://a.link.for/#{resp["data"]["id"]}/declaration_request_confidant_person.0.PRIMARY.RELATIONSHIP.COURT_DECISION.jpeg"
               }
             ] == resp["urgent"]["documents"]
    end

    test "declaration request is created for person without tax_id", %{conn: conn} do
      template()

      gen_sequence_number()

      expect(MPIMock, :search, fn params, _ ->
        {:ok,
         %{
           "data" => [
             params
             |> Map.put("id", "b5350f79-f2ca-408f-b15d-1ae0a8cc861c")
             |> Map.put("authentication_methods", [
               %{"type" => "OTP", "phone_number" => "+380508887700"}
             ])
           ]
         }}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(OTPVerificationMock, :initialize, fn _number, _headers ->
        {:ok, %{}}
      end)

      age = 16
      person_birth_date = Timex.shift(Timex.today(), years: -age) |> to_string()

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["declaration_request", "person", "birth_date"], person_birth_date)

      uaddresses_mock_expect()

      person =
        declaration_request_params
        |> get_in(~W(declaration_request person))
        |> Map.put("authentication_methods", [%{"type" => "OFFLINE"}])
        |> Map.delete("tax_id")

      declaration_request_params = put_in(declaration_request_params, ~W(declaration_request person), person)

      new_declaration =
        declaration_request_params
        |> Map.get("declaration_request")
        |> put_in(~W(person first_name), "Василь")
        |> put_in(~W(person last_name), "Шевченко")
        |> put_in(~W(person second_name), "Макарович")

      le_id = "8799e3b6-34e7-4798-ba70-d897235d2b6d"
      d1 = clone_declaration_request(new_declaration, le_id, "NEW")
      d2 = clone_declaration_request(declaration_request_params["declaration_request"], le_id, "NEW")

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), Jason.encode!(declaration_request_params))
        |> json_response(200)

      assert_show_response_schema(resp, "declaration_request")
      assert "NEW" = resp["data"]["status"]

      declaration_request = Repo.get(DeclarationRequest, d1.id)

      refute declaration_request.mpi_id
      assert "NEW" = declaration_request.status
      assert "CANCELLED" = Repo.get(DeclarationRequest, d2.id).status
    end

    test "declaration request is created without verification", %{conn: conn} do
      gen_sequence_number()

      expect(MPIMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["declaration_request", "person", "first_name"], "Тест")

      tax_id = get_in(declaration_request_params, ~w(declaration_request person tax_id))
      html_template("<html><body>Printout form for declaration request. tax_id = #{tax_id}</body></html>")
      uaddresses_mock_expect()

      decoded = declaration_request_params["declaration_request"]
      d1 = clone_declaration_request(decoded, "8799e3b6-34e7-4798-ba70-d897235d2b6d", "NEW")
      d2 = clone_declaration_request(decoded, "8799e3b6-34e7-4798-ba70-d897235d2b6d", "NEW")

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post("/api/declaration_requests", Jason.encode!(declaration_request_params))

      resp = json_response(conn, 200)

      id = resp["data"]["id"]

      assert_show_response_schema(resp, "declaration_request")

      assert to_string(Date.utc_today()) == resp["data"]["start_date"]
      assert {:ok, _} = Date.from_iso8601(resp["data"]["end_date"])

      declaration_request = DeclarationRequests.get_by_id!(id)
      assert declaration_request.data["legal_entity"]["id"]
      assert declaration_request.data["division"]["id"]
      assert declaration_request.data["employee"]["id"]
      # TODO: turn this into DB checks
      #
      # assert "NEW" = resp["status"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["updated_by"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["inserted_by"]
      # assert %{"number" => "+380508887700", "type" => "OTP"} = resp["authentication_method_current"]

      assert "<html><body>Printout form for declaration request. tax_id = #{tax_id}</body></html>" ==
               resp["data"]["content"]

      assert %{"type" => "NA"} = resp["urgent"]["authentication_method_current"]
      refute resp["data"]["urgent"]["documents"]

      assert "CANCELLED" = Repo.get(DeclarationRequest, d1.id).status
      assert "CANCELLED" = Repo.get(DeclarationRequest, d2.id).status
    end

    test "Declaration request creating with employee that has wrong speciality", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "ec7b4900-d7bf-4794-98cd-0fd72f4321ec")
      insert(:prm, :medical_service_provider, legal_entity: legal_entity)
      party = insert(:prm, :party, id: "d9382ec3-4d88-4c9a-ac71-153db6f04f96")
      insert(:prm, :party_user, party: party)
      division = insert(:prm, :division, id: "31506899-55a5-4011-b88c-10ba90c5e9bd", legal_entity: legal_entity)

      pharmacist2 = Map.put(doctor(), "specialities", [%{speciality: "PHARMACIST2"}])

      insert(
        :prm,
        :employee,
        id: "b03f057f-aa84-4152-b6e5-3905ba821b66",
        division: division,
        party: party,
        legal_entity: legal_entity,
        additional_info: pharmacist2
      )

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["declaration_request", "division_id"], "31506899-55a5-4011-b88c-10ba90c5e9bd")
        |> put_in(["declaration_request", "employee_id"], "b03f057f-aa84-4152-b6e5-3905ba821b66")

      uaddresses_mock_expect()

      conn =
        conn
        |> put_req_header("x-consumer-id", "b03f057f-aa84-4152-b6e5-3905ba821b66")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "ec7b4900-d7bf-4794-98cd-0fd72f4321ec"}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)

      resp = json_response(conn, 422)

      assert [
               %{
                 "entry" => "$.data",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" =>
                       "Employee's speciality does not belong to a doctor: PEDIATRICIAN, THERAPIST, FAMILY_DOCTOR",
                     "params" => [
                       ["allowed_types", "PEDIATRICIAN, THERAPIST, FAMILY_DOCTOR"]
                     ],
                     "rule" => "speciality_inclusion"
                   }
                 ]
               }
             ] == resp["error"]["invalid"]
    end

    test "declaration request document validation: series_number_document", %{conn: conn} do
      gen_sequence_number()
      template()

      expect(MPIMock, :search, fn params, _ ->
        {:ok,
         %{
           "data" => [
             params
             |> Map.put("id", "b5350f79-f2ca-408f-b15d-1ae0a8cc861c")
             |> Map.put("authentication_methods", [
               %{"type" => "OTP", "phone_number" => "+380508887700"}
             ])
           ]
         }}
      end)

      expect(OTPVerificationMock, :initialize, fn _number, _headers ->
        {:ok, %{}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()

      uaddresses_mock_expect()

      assert conn
             |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
             |> put_req_header(
               "x-consumer-metadata",
               Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"})
             )
             |> post(declaration_request_path(conn, :create), declaration_request_params)
             |> json_response(200)

      declaration_request_params =
        declaration_request_params
        |> put_in(["declaration_request", "person", "documents"], [
          %{
            type: "PASSPORT",
            number: "120518",
            issued_at: "2014-02-12",
            issued_by: "Збухівський РО ГО МЖД"
          }
        ])

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header(
          "x-consumer-metadata",
          Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"})
        )
        |> post(declaration_request_path(conn, :create), declaration_request_params)
        |> json_response(422)

      assert resp["error"]["invalid"]

      declaration_request_params =
        declaration_request_params
        |> put_in(["declaration_request", "person", "documents"], [
          %{
            type: "PASSPORT",
            number: "ЫЯ120518",
            issued_at: "2014-02-12",
            issued_by: "Збухівський РО ГО МЖД"
          }
        ])

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header(
          "x-consumer-metadata",
          Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"})
        )
        |> post(declaration_request_path(conn, :create), declaration_request_params)
        |> json_response(422)

      assert resp["error"]["invalid"]
    end

    test "declaration request document validation: id_card", %{conn: conn} do
      gen_sequence_number()
      template()

      expect(MPIMock, :search, fn params, _ ->
        {:ok,
         %{
           "data" => [
             params
             |> Map.put("id", "b5350f79-f2ca-408f-b15d-1ae0a8cc861c")
             |> Map.put("authentication_methods", [
               %{"type" => "OTP", "phone_number" => "+380508887700"}
             ])
           ]
         }}
      end)

      expect(OTPVerificationMock, :initialize, fn _number, _headers ->
        {:ok, %{}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      declaration_request =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()

      declaration_request_params =
        declaration_request
        |> put_in(
          ["declaration_request", "person", "unzr"],
          "#{String.replace(declaration_request["declaration_request"]["person"]["birth_date"], "-", "")}-00000"
        )
        |> put_in(["declaration_request", "person", "documents"], [
          %{
            type: "NATIONAL_ID",
            number: "123456789",
            issued_at: "2014-02-12",
            issued_by: "Збухівський РО ГО МЖД"
          },
          %{
            type: "BIRTH_CERTIFICATE",
            number: "1234567"
          }
        ])

      uaddresses_mock_expect()

      assert conn
             |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
             |> put_req_header(
               "x-consumer-metadata",
               Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"})
             )
             |> post(declaration_request_path(conn, :create), declaration_request_params)
             |> json_response(200)

      declaration_request_params =
        declaration_request_params
        |> put_in(["declaration_request", "person", "documents"], [
          %{
            type: "NATIONAL_ID",
            number: "ы12345678",
            issued_at: "2014-02-12",
            issued_by: "Збухівський РО ГО МЖД"
          },
          %{
            type: "BIRTH_CERTIFICATE",
            number: "1234567"
          }
        ])

      resp =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header(
          "x-consumer-metadata",
          Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"})
        )
        |> post(declaration_request_path(conn, :create), declaration_request_params)
        |> json_response(422)

      assert resp["error"]["invalid"]
    end
  end

  describe "Global parameters return 404" do
    setup %{conn: conn} do
      insert_dictionaries()
      {:ok, %{conn: conn}}
    end

    test "returns error if global parameters do not exist", %{conn: conn} do
      declaration_request_params = File.read!("../core/test/data/declaration_request.json")
      uaddresses_mock_expect()

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)

      json_response(conn, 422)
    end
  end

  describe "Employee does not exist" do
    setup %{conn: conn} do
      insert(:prm, :global_parameter, %{parameter: "adult_age", value: "18"})
      insert(:prm, :global_parameter, %{parameter: "declaration_term", value: "40"})
      insert(:prm, :global_parameter, %{parameter: "declaration_term_unit", value: "YEARS"})

      insert_dictionaries()
      {:ok, %{conn: conn}}
    end

    test "returns error if employee doesn't exist", %{conn: conn} do
      wrong_id = "2f650a5c-7a04-4615-a1e7-00fa41bf160d"

      declaration_request_params =
        "../core/test/data/declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["declaration_request", "employee_id"], wrong_id)

      uaddresses_mock_expect()

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
        |> post(declaration_request_path(conn, :create), Jason.encode!(declaration_request_params))

      resp = json_response(conn, 422)

      assert %{
               "meta" => %{
                 "code" => 422,
                 "url" => "http://www.example.com/api/declaration_requests",
                 "type" => "object",
                 "request_id" => _
               }
             } = resp
    end
  end

  describe "Settlement does not exist" do
    setup %{conn: conn} do
      insert_dictionaries()
      {:ok, %{conn: conn}}
    end

    test "validation error is returned", %{conn: conn} do
      declaration_request_params = File.read!("../core/test/data/declaration_request.json")

      expect(UAddressesMock, :validate_addresses, fn _, _headers ->
        {:error,
         %{
           "error" => %{
             "invalid" => [
               %{
                 "entry" => "$.addresses[0].settlement_id",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "settlement with id = adaa4abf-f530-461c-bcbf-a0ac210d955b does not exist",
                     "params" => []
                   }
                 ]
               },
               %{
                 "entry" => "$.addresses[1].settlement_id",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "settlement with id = adaa4abf-f530-461c-bcbf-a0ac210d955b does not exist",
                     "params" => []
                   }
                 ]
               }
             ]
           }
         }}
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: ""}))
        |> post(declaration_request_path(conn, :create), declaration_request_params)

      assert resp = json_response(conn, 422)["error"]

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.addresses[0].settlement_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "settlement with id = adaa4abf-f530-461c-bcbf-a0ac210d955b does not exist",
                       "params" => []
                     }
                   ]
                 },
                 %{
                   "entry" => "$.addresses[1].settlement_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "settlement with id = adaa4abf-f530-461c-bcbf-a0ac210d955b does not exist",
                       "params" => []
                     }
                   ]
                 }
               ]
             } = resp
    end
  end

  describe "invalid schema" do
    test "Declaration Request: authentication_methods invalid", %{conn: conn} do
      params = %{
        "name" => "AUTHENTICATION_METHOD",
        "values" => %{
          "2FA" => "two-factor",
          "OTP" => "one-time pass"
        },
        "labels" => ["SYSTEM"],
        "is_active" => true
      }

      patch(conn, dictionary_path(conn, :update, "AUTHENTICATION_METHOD"), params)

      content =
        put_in(get_declaration_request(), ~W(person authentication_methods), [
          %{"phone_number" => "+380508887700", "type" => "IDGAF"}
        ])

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), %{"declaration_request" => content})

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.declaration_request.person.authentication_methods.[0].type",
                     "entry_type" => "json_data_property",
                     "rules" => [
                       %{
                         "description" => "value is not allowed in enum",
                         "params" => ["2FA", "OTP"],
                         "rule" => "inclusion"
                       }
                     ]
                   }
                 ]
               }
             } = json_response(conn, 422)
    end

    test "Declaration Request: JSON schema documents.type invalid", %{conn: conn} do
      params = %{
        "name" => "DOCUMENT_TYPE",
        "values" => %{
          "PASSPORT" => "passport"
        },
        "labels" => ["SYSTEM"],
        "is_active" => true
      }

      patch(conn, dictionary_path(conn, :update, "DOCUMENT_TYPE"), params)
      content = put_in(get_declaration_request(), ~W(person documents), invalid_documents())

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), %{"declaration_request" => content})

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.declaration_request.person.documents.[0]",
                     "entry_type" => "json_data_property",
                     "rules" => [
                       %{
                         "description" => "expected exactly one of the schemata to match, but none of them did",
                         "params" => [],
                         "rule" => "schemata"
                       }
                     ]
                   }
                 ]
               }
             } = json_response(conn, 422)
    end

    test "Declaration Request: JSON schema documents_relationship.type invalid", %{conn: conn} do
      params = %{
        "name" => "DOCUMENT_RELATIONSHIP_TYPE",
        "values" => %{
          "COURT_DECISION" => "court decision"
        },
        "labels" => ["SYSTEM"],
        "is_active" => true
      }

      patch(conn, dictionary_path(conn, :update, "DOCUMENT_RELATIONSHIP_TYPE"), params)
      request = get_declaration_request()

      confidant_person =
        request
        |> get_in(~W(person confidant_person))
        |> List.first()
        |> Map.put("documents_relationship", invalid_documents())

      content = put_in(request, ~W(person confidant_person), [confidant_person])

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), %{"declaration_request" => content})

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.declaration_request.person.confidant_person.[0].documents_relationship.[0].type",
                     "entry_type" => "json_data_property",
                     "rules" => [
                       %{
                         "description" => "value is not allowed in enum",
                         "params" => ["COURT_DECISION"],
                         "rule" => "inclusion"
                       }
                     ]
                   }
                 ]
               }
             } = json_response(conn, 422)
    end

    test "Declaration Request: JSON schema gender invalid", %{conn: conn} do
      params = %{
        "name" => "GENDER",
        "values" => %{
          "FEMALE" => "woman",
          "MALE" => "man"
        },
        "labels" => ["SYSTEM"],
        "is_active" => true
      }

      patch(conn, dictionary_path(conn, :update, "GENDER"), params)
      content = put_in(get_declaration_request(), ~W(person gender), "ORC")

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), %{"declaration_request" => content})

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.declaration_request.person.gender",
                     "entry_type" => "json_data_property",
                     "rules" => [
                       %{
                         "description" => "value is not allowed in enum",
                         "params" => ["FEMALE", "MALE"],
                         "rule" => "inclusion"
                       }
                     ]
                   }
                 ]
               }
             } = json_response(conn, 422)
    end

    test "Declaration Request: person name is too long", %{conn: conn} do
      first_name = String.duplicate("Галина", 43)
      last_name = String.duplicate("Галина", 43)
      second_name = String.duplicate("Галина", 43)

      content =
        get_declaration_request()
        |> put_in(~W(person first_name), first_name)
        |> put_in(~W(person last_name), last_name)
        |> put_in(~W(person second_name), second_name)

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post(declaration_request_path(conn, :create), %{"declaration_request" => content})

      assert %{"error" => %{"invalid" => errors}} = json_response(conn, 422)

      assert %{
               "entry" => "$.declaration_request.person.first_name",
               "entry_type" => "json_data_property",
               "rules" => [
                 %{
                   "description" => "expected value to have a maximum length of 255 but was 258",
                   "params" => %{"max" => 255},
                   "rule" => "length"
                 }
               ]
             } in errors

      assert %{
               "entry" => "$.declaration_request.person.last_name",
               "entry_type" => "json_data_property",
               "rules" => [
                 %{
                   "description" => "expected value to have a maximum length of 255 but was 258",
                   "params" => %{"max" => 255},
                   "rule" => "length"
                 }
               ]
             } in errors

      assert %{
               "entry" => "$.declaration_request.person.second_name",
               "entry_type" => "json_data_property",
               "rules" => [
                 %{
                   "description" => "expected value to have a maximum length of 255 but was 258",
                   "params" => %{"max" => 255},
                   "rule" => "length"
                 }
               ]
             } in errors
    end
  end

  def clone_declaration_request(params, legal_entity_id, status) do
    declaration_request_params = %{
      data: %{
        person: params["person"],
        employee: %{
          id: params["employee_id"]
        },
        legal_entity: %{
          id: legal_entity_id
        }
      },
      status: status,
      authentication_method_current: %{},
      documents: [],
      printout_content: "something",
      inserted_by: "f47f94fd-2d77-4b7e-b444-4955812c2a77",
      updated_by: "f47f94fd-2d77-4b7e-b444-4955812c2a77",
      channel: DeclarationRequest.channel(:mis),
      declaration_number: NumberGenerator.generate(1, 2)
    }

    %DeclarationRequest{}
    |> Ecto.Changeset.change(declaration_request_params)
    |> Repo.insert!()
  end

  defp insert_dictionaries do
    insert(:il, :dictionary_phone_type)
    insert(:il, :dictionary_document_type)
    insert(:il, :dictionary_authentication_method)
    insert(:il, :dictionary_document_relationship_type)
  end

  defp invalid_documents do
    [%{"type" => "lol_kek_cheburek", "number" => "120519"}]
  end

  defp get_declaration_request do
    "../core/test/data/declaration_request.json"
    |> File.read!()
    |> Jason.decode!()
    |> Map.fetch!("declaration_request")
  end

  defp uaddresses_mock_expect do
    expect(UAddressesMock, :validate_addresses, fn _, _ ->
      {:ok, %{"data" => %{}}}
    end)
  end
end
