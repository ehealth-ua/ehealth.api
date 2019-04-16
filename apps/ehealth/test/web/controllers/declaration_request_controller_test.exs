defmodule EHealth.Web.DeclarationRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Mox
  import Core.Expectations.Signature
  alias Ecto.UUID
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Utils.NumberGenerator
  alias HTTPoison.Response

  setup :verify_on_exit!

  describe "list declaration requests" do
    test "no legal_entity_id match", %{conn: conn} do
      msp()
      legal_entity_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params = prepare_params(fixture_params())
        insert(:il, :declaration_request, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by legal_entity_id", %{conn: conn} do
      msp()
      legal_entity_id = UUID.generate()
      employee_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :employee, :id], employee_id)
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> prepare_params()

        insert(
          :il,
          :declaration_request,
          params
        )
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "no employee_id match", %{conn: conn} do
      msp()
      legal_entity_id = UUID.generate()
      employee_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> prepare_params()

        insert(:il, :declaration_request, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index, %{employee_id: employee_id}))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by employee_id", %{conn: conn} do
      msp()
      legal_entity_id = UUID.generate()
      employee_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> put_in([:data, :employee, :id], employee_id)
          |> prepare_params()

        insert(:il, :declaration_request, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index, %{employee_id: employee_id}))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "no status match", %{conn: conn} do
      msp()
      legal_entity_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> prepare_params()

        insert(:il, :declaration_request, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index, %{status: "ACTIVE"}))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by status", %{conn: conn} do
      msp()
      legal_entity_id = UUID.generate()
      status = "ACTIVE"

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> put_in([:status], status)
          |> prepare_params()

        insert(:il, :declaration_request, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index, %{status: status}))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "match by legal_entity_id, employee_id, status", %{conn: conn} do
      msp()
      legal_entity_id = UUID.generate()
      employee_id = UUID.generate()
      status = "ACTIVE"

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> put_in([:data, :employee, :id], employee_id)
          |> put_in([:status], status)
          |> prepare_params()

        insert(:il, :declaration_request, params)
      end)

      resp =
        conn
        |> put_client_id_header(legal_entity_id)
        |> get(
          declaration_request_path(conn, :index, %{
            status: status,
            employee_id: employee_id
          })
        )
        |> json_response(200)

      assert_count_declaration_request_list(resp, 2)
    end
  end

  describe "approve declaration_request" do
    test "approve NEW declaration_request", %{conn: conn} do
      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 1}}}
      end)

      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, fn _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      party = insert(:prm, :party)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity_id: legal_entity.id)

      declaration_request =
        insert(
          :il,
          :declaration_request,
          documents: [%{"type" => "ok", "verb" => "HEAD"}],
          data: %{"employee" => %{"id" => employee_id}},
          data_employee_id: employee_id
        )

      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, declaration_request_path(conn, :approve, declaration_request))

      resp = json_response(conn, 200)
      assert DeclarationRequest.status(:approved) == resp["data"]["status"]
    end

    test "approve when limit exited and person has NOT declarations with doctor", %{conn: conn} do
      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 4}}}
      end)

      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, fn _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      party = insert(:prm, :party)
      legal_entity = insert(:prm, :legal_entity)

      # THERAPIST
      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          party: party,
          legal_entity_id: legal_entity.id,
          speciality: employee_speciality(%{"speciality" => "THERAPIST"})
        )

      # PEDIATRICIAN
      insert(
        :prm,
        :employee,
        party: party,
        legal_entity_id: legal_entity.id,
        speciality: employee_speciality(%{"speciality" => "PEDIATRICIAN"})
      )

      # FAMILY_DOCTOR
      insert(
        :prm,
        :employee,
        party: party,
        legal_entity_id: legal_entity.id,
        speciality: employee_speciality(%{"speciality" => "FAMILY_DOCTOR"})
      )

      data = %{"employee" => %{"id" => employee_id}}

      insert(
        :il,
        :declaration_request,
        data: data,
        data_employee_id: employee_id,
        status: DeclarationRequest.status(:approved)
      )

      declaration_request =
        insert(
          :il,
          :declaration_request,
          documents: [%{"type" => "ok", "verb" => "HEAD"}],
          data: data,
          mpi_id: UUID.generate()
        )

      current_speciality_limits = Application.get_env(:core, :employee_speciality_limits)

      on_exit(fn ->
        Application.put_env(:core, :employee_speciality_limits, current_speciality_limits)
      end)

      Application.put_env(
        :core,
        :employee_speciality_limits,
        therapist_declaration_limit: 5,
        pediatrician_declaration_limit: 6,
        family_doctor_declaration_limit: 7
      )

      # current doctor limit = 5
      # doctor's declaration count = 5
      resp =
        conn
        |> put_client_id_header(UUID.generate())
        |> patch(declaration_request_path(conn, :approve, declaration_request))
        |> json_response(422)

      assert resp["error"]["message"] == "This doctor has 5 declarations and could not sign more"
    end

    test "approve when limit exited and person has declarations with doctor", %{conn: conn} do
      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 3}}}
      end)

      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, fn _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      party = insert(:prm, :party)
      legal_entity = insert(:prm, :legal_entity)

      # THERAPIST
      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          party: party,
          legal_entity_id: legal_entity.id,
          speciality: employee_speciality(%{"speciality" => "THERAPIST"})
        )

      # PEDIATRICIAN
      insert(
        :prm,
        :employee,
        party: party,
        legal_entity_id: legal_entity.id,
        speciality: employee_speciality(%{"speciality" => "PEDIATRICIAN"})
      )

      # FAMILY_DOCTOR
      insert(
        :prm,
        :employee,
        party: party,
        legal_entity_id: legal_entity.id,
        speciality: employee_speciality(%{"speciality" => "FAMILY_DOCTOR"})
      )

      data = %{"employee" => %{"id" => employee_id}}

      insert(
        :il,
        :declaration_request,
        data: data,
        status: DeclarationRequest.status(:approved)
      )

      declaration_request =
        insert(
          :il,
          :declaration_request,
          documents: [%{"type" => "ok", "verb" => "HEAD"}],
          data: data,
          data_employee_id: employee_id,
          mpi_id: UUID.generate()
        )

      current_speciality_limits = Application.get_env(:core, :employee_speciality_limits)

      on_exit(fn ->
        Application.put_env(:core, :employee_speciality_limits, current_speciality_limits)
      end)

      Application.put_env(
        :core,
        :employee_speciality_limits,
        therapist_declaration_limit: 5,
        pediatrician_declaration_limit: 6,
        family_doctor_declaration_limit: 7
      )

      # current doctor limit = 5
      # doctor's declaration count = 5
      # person's declaration count by doctor = 1
      resp =
        conn
        |> put_client_id_header(UUID.generate())
        |> patch(declaration_request_path(conn, :approve, declaration_request))
        |> json_response(200)

      assert DeclarationRequest.status(:approved) == resp["data"]["status"]
    end

    test "all employee types are ignored except DOCTOR", %{conn: conn} do
      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 3}}}
      end)

      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, fn _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      party = insert(:prm, :party)
      legal_entity = insert(:prm, :legal_entity)

      # THERAPIST
      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          party: party,
          legal_entity_id: legal_entity.id,
          speciality: employee_speciality(%{"speciality" => "THERAPIST"})
        )

      # PEDIATRICIAN
      insert(
        :prm,
        :employee,
        party: party,
        legal_entity_id: legal_entity.id,
        speciality: employee_speciality(%{"speciality" => "PEDIATRICIAN"})
      )

      # FAMILY_DOCTOR
      insert(
        :prm,
        :employee,
        party: party,
        legal_entity_id: legal_entity.id,
        speciality: employee_speciality(%{"speciality" => "FAMILY_DOCTOR"})
      )

      # OWNER
      insert(
        :prm,
        :employee,
        party: party,
        legal_entity_id: legal_entity.id,
        employee_type: "OWNER",
        speciality: nil
      )

      data = %{"employee" => %{"id" => employee_id}}

      insert(
        :il,
        :declaration_request,
        data: data,
        data_employee_id: employee_id,
        status: DeclarationRequest.status(:approved)
      )

      declaration_request =
        insert(
          :il,
          :declaration_request,
          documents: [%{"type" => "ok", "verb" => "HEAD"}],
          data: data,
          data_employee_id: employee_id,
          mpi_id: UUID.generate()
        )

      current_speciality_limits = Application.get_env(:core, :employee_speciality_limits)

      on_exit(fn ->
        Application.put_env(:core, :employee_speciality_limits, current_speciality_limits)
      end)

      Application.put_env(
        :core,
        :employee_speciality_limits,
        therapist_declaration_limit: 5,
        pediatrician_declaration_limit: 6,
        family_doctor_declaration_limit: 7
      )

      # current doctor limit = 5
      # doctor's declaration count = 5
      # person's declaration count by doctor = 1
      resp =
        conn
        |> put_client_id_header(UUID.generate())
        |> patch(declaration_request_path(conn, :approve, declaration_request))
        |> json_response(200)

      assert DeclarationRequest.status(:approved) == resp["data"]["status"]
    end

    test "approve APPROVED declaration_request", %{conn: conn} do
      declaration_request =
        insert(
          :il,
          :declaration_request,
          status: DeclarationRequest.status(:approved)
        )

      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, declaration_request_path(conn, :approve, declaration_request))

      resp = json_response(conn, 409)
      assert "Invalid transition" == get_in(resp, ["error", "message"])
    end
  end

  describe "approve declaration request without documents" do
    test "approve NEW declaration_request with OFFLINE authentication method", %{conn: conn} do
      expect(MediaStorageMock, :create_signed_url, 3, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 3, fn
        _, "declaration_request_person.DECLARATION_FORM.jpeg" ->
          {:error, %HTTPoison.Error{id: nil, reason: :timeout}}

        _, _ ->
          {:ok, %HTTPoison.Response{status_code: 404}}
      end)

      declaration_request =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "OFFLINE"
          },
          documents: [
            %{"type" => "ok", "verb" => "HEAD"},
            %{"type" => "empty", "verb" => "HEAD"},
            %{"type" => "person.DECLARATION_FORM", "verb" => "HEAD"}
          ]
        )

      assert conn
             |> put_client_id_header(UUID.generate())
             |> patch(declaration_request_path(conn, :approve, declaration_request))
             |> json_response(500)
    end
  end

  describe "get declaration request by id" do
    test "get declaration request by invalid id", %{conn: conn} do
      msp()
      id = UUID.generate()
      another_id = UUID.generate()
      conn = put_client_id_header(conn, id)

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, declaration_request_path(conn, :show, another_id))
      end
    end

    test "get declaration request by invalid legal_entity_id", %{conn: conn} do
      msp()
      %{id: id} = insert(:il, :declaration_request)
      conn = put_client_id_header(conn, UUID.generate())

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, declaration_request_path(conn, :show, id))
      end
    end

    test "get declaration request by id", %{conn: conn} do
      msp()

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_hash"}}}
      end)

      %{id: id, data: data} = insert(:il, :declaration_request, prepare_params(fixture_params()))

      conn = put_client_id_header(conn, get_in(data, [:legal_entity, :id]))
      conn = get(conn, declaration_request_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "urgent")
      assert "some_hash" == get_in(resp, ["data", "seed"])
    end
  end

  describe "resend otp" do
    test "when declaration request id is invalid", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())

      assert_raise Ecto.NoResultsError, fn ->
        post(conn, declaration_request_path(conn, :resend_otp, UUID.generate()))
      end
    end

    test "when declaration request status is not NEW", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())

      %{id: id} =
        insert(
          :il,
          :declaration_request,
          status: DeclarationRequest.status(:approved)
        )

      conn = post(conn, declaration_request_path(conn, :resend_otp, id))
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      error = resp["error"]
      assert Map.has_key?(error, "invalid")
      assert 1 == length(error["invalid"])
      invalid = Enum.at(error["invalid"], 0)
      assert "$.status" == invalid["entry"]
      assert 1 == length(invalid["rules"])
      rule = Enum.at(invalid["rules"], 0)
      assert "incorrect status" == rule["description"]
    end

    test "when declaration request auth method is not OTP", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())

      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => DeclarationRequest.authentication_method(:offline)
          }
        )

      conn = post(conn, declaration_request_path(conn, :resend_otp, id))
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      error = resp["error"]
      assert Map.has_key?(error, "invalid")
      assert 1 == length(error["invalid"])
      invalid = Enum.at(error["invalid"], 0)
      assert "$.authentication_method_current" == invalid["entry"]
      assert 1 == length(invalid["rules"])
      rule = Enum.at(invalid["rules"], 0)
      assert "Auth method is not OTP" == rule["description"]
    end

    test "when declaration request fields are correct", %{conn: conn} do
      expect(OTPVerificationMock, :initialize, fn _number, _headers ->
        {:ok, %{"status" => "NEW"}}
      end)

      conn = put_client_id_header(conn, UUID.generate())

      %{id: id} =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => DeclarationRequest.authentication_method(:otp),
            "number" => 111
          }
        )

      conn = post(conn, declaration_request_path(conn, :resend_otp, id))
      resp = json_response(conn, 200)
      assert Map.has_key?(resp, "data")
      assert %{"status" => "NEW"} == resp["data"]
    end
  end

  describe "get documents" do
    test "when declaration id is invalid", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        get(conn, declaration_request_path(conn, :documents, UUID.generate()))
      end
    end

    test "when declaration id is valid", %{conn: conn} do
      expect(MediaStorageMock, :create_signed_url, 3, fn _, _, resource_name, resource_id, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://a.link.for/#{resource_id}/#{resource_name}"}}}
      end)

      params =
        fixture_params()
        |> Map.put(:documents, [
          %{"type" => "person.PASSPORT"},
          %{"type" => "person.DECLARATION_FORM"},
          %{"type" => "confidant_person.0.PRIMARY.RELATIONSHIP.COURT_DECISION"}
        ])
        |> prepare_params()

      %{id: id, declaration_id: declaration_id} = insert(:il, :declaration_request, params)
      conn = get(conn, declaration_request_path(conn, :documents, declaration_id))
      result = json_response(conn, 200)["data"]

      expected_result = [
        %{
          "type" => "confidant_person.0.PRIMARY.RELATIONSHIP.COURT_DECISION",
          "url" =>
            "http://a.link.for/#{id}/declaration_request_confidant_person.0.PRIMARY.RELATIONSHIP.COURT_DECISION.jpeg"
        },
        %{
          "type" => "person.DECLARATION_FORM",
          "url" => "http://a.link.for/#{id}/declaration_request_person.DECLARATION_FORM.jpeg"
        },
        %{
          "type" => "person.PASSPORT",
          "url" => "http://a.link.for/#{id}/declaration_request_person.PASSPORT.jpeg"
        }
      ]

      assert expected_result == result
    end
  end

  describe "sign declaration request" do
    test "success", %{conn: conn} do
      expect(OPSMock, :create_declaration_with_termination_logic, fn params, _headers ->
        {:ok, %{"data" => params}}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(MPIMock, :create_or_update_person, fn _params, _headers ->
        {:ok, %Response{body: Jason.encode!(%{"data" => string_params_for(:person)}), status_code: 200}}
      end)

      expect(CasherMock, :update_person_data, fn _params, _headers ->
        {:ok, %{}}
      end)

      data =
        "../core/test/data/declaration_request/sign_request.json"
        |> File.read!()
        |> Jason.decode!()

      tax_id = get_in(data, ~w(employee party tax_id))
      employee_id = get_in(data, ~w(employee id))

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      insert(:prm, :employee, id: employee_id, legal_entity_id: legal_entity_id)
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))

      params =
        %{
          id: data["id"],
          status: DeclarationRequest.status(:approved),
          data: %{
            "person" => get_person(),
            "declaration_id" => data["declaration_id"],
            "division" => data["division"],
            "employee" => data["employee"],
            "end_date" => data["end_date"],
            "scope" => data["scope"],
            "start_date" => data["start_date"],
            "legal_entity" => data["legal_entity"]
          },
          printout_content: data["content"],
          authentication_method_current: %{
            "type" => DeclarationRequest.authentication_method(:na)
          }
        }
        |> prepare_params()

      %{id: declaration_id, declaration_number: declaration_number} = insert(:il, :declaration_request, params)

      signed_declaration_request =
        data
        |> Map.put("seed", "some_current_hash")
        |> Map.put("declaration_number", declaration_number)

      drfo_signed_content(signed_declaration_request, tax_id)

      conn
      |> Plug.Conn.put_req_header("drfo", tax_id)
      |> put_client_id_header(legal_entity_id)
      |> put_consumer_id_header(user_id)
      |> patch(declaration_request_path(conn, :sign, declaration_id), %{
        "signed_declaration_request" =>
          signed_declaration_request
          |> Jason.encode!()
          |> Base.encode64(),
        "signed_content_encoding" => "base64"
      })
      |> json_response(200)
    end

    test "can't insert person", %{conn: conn} do
      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(MPIMock, :create_or_update_person, fn _params, _headers ->
        errors = %{
          "invalid" => [
            %{
              "entry" => "$.last_name",
              "entry_type" => "json_data_property",
              "rules" => [
                %{
                  "description" => "has already been taken",
                  "params" => [],
                  "rule" => nil
                }
              ]
            }
          ],
          "message" =>
            "Validation failed. You can find validators description at our API Manifest: http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors.",
          "type" => "validation_failed"
        }

        {:ok, %Response{status_code: 422, body: Jason.encode!(errors)}}
      end)

      data =
        "../core/test/data/declaration_request/sign_request.json"
        |> File.read!()
        |> Jason.decode!()

      tax_id = get_in(data, ~w(employee party tax_id))
      employee_id = get_in(data, ~w(employee id))

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      insert(:prm, :employee, id: employee_id, legal_entity_id: legal_entity_id)
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))

      params =
        %{
          id: data["id"],
          status: DeclarationRequest.status(:approved),
          data: %{
            "person" => get_person(),
            "declaration_id" => data["declaration_id"],
            "division" => data["division"],
            "employee" => data["employee"],
            "end_date" => data["end_date"],
            "scope" => data["scope"],
            "start_date" => data["start_date"],
            "legal_entity" => data["legal_entity"]
          },
          printout_content: data["content"],
          authentication_method_current: %{
            "type" => DeclarationRequest.authentication_method(:na)
          }
        }
        |> prepare_params()

      %{id: declaration_id, declaration_number: declaration_number} = insert(:il, :declaration_request, params)

      signed_declaration_request =
        data
        |> Map.put("seed", "some_current_hash")
        |> Map.put("declaration_number", declaration_number)

      drfo_signed_content(signed_declaration_request, "3173108921")

      assert response =
               conn
               |> Plug.Conn.put_req_header("drfo", tax_id)
               |> put_client_id_header(legal_entity_id)
               |> put_consumer_id_header(user_id)
               |> patch(declaration_request_path(conn, :sign, declaration_id), %{
                 "signed_declaration_request" =>
                   signed_declaration_request
                   |> Jason.encode!()
                   |> Base.encode64(),
                 "signed_content_encoding" => "base64"
               })
               |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.last_name",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "has already been taken",
                       "params" => [],
                       "rule" => nil
                     }
                   ]
                 }
               ]
             } = response["error"]
    end

    test "invalid request", %{conn: conn} do
      data =
        "../core/test/data/declaration_request/sign_request.json"
        |> File.read!()
        |> Jason.decode!()

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      %{id: declaration_id} = insert(:il, :declaration_request)

      assert [err1, err2] =
               conn
               |> put_client_id_header(legal_entity_id)
               |> patch(declaration_request_path(conn, :sign, declaration_id), %{
                 "data" => %{
                   "signed_declaration_request" => data,
                   "signed_content_encoding" => "base64"
                 }
               })
               |> json_response(422)
               |> get_in(["error", "invalid"])

      assert "$.signed_content_encoding" == err1["entry"]
      assert "$.signed_declaration_request" == err2["entry"]
    end

    test "success for person with no_tax_id", %{conn: conn} do
      expect(OPSMock, :create_declaration_with_termination_logic, fn params, _headers ->
        {:ok, %{"data" => params}}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(MPIMock, :create_or_update_person, fn _params, _headers ->
        {:ok,
         %Response{
           body: Jason.encode!(%{"data" => string_params_for(:person, no_tax_id: true, tax_id: "")}),
           status_code: 200
         }}
      end)

      expect(CasherMock, :update_person_data, fn _params, _headers ->
        {:ok, %{}}
      end)

      data =
        "../core/test/data/declaration_request/sign_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(~w(person tax_id), "")
        |> put_in(~w(employee party tax_id), "")
        |> put_in(~w(person no_tax_id), true)

      tax_id = get_in(data, ~w(employee party tax_id))
      employee_id = get_in(data, ~w(employee id))

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      insert(:prm, :employee, id: employee_id, legal_entity_id: legal_entity_id)
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))

      params =
        %{
          id: data["id"],
          status: DeclarationRequest.status(:approved),
          data: %{
            "person" => data["person"],
            "declaration_id" => data["declaration_id"],
            "division" => data["division"],
            "employee" => data["employee"],
            "end_date" => data["end_date"],
            "scope" => data["scope"],
            "start_date" => data["start_date"],
            "legal_entity" => data["legal_entity"]
          },
          printout_content: data["content"],
          authentication_method_current: %{
            "type" => DeclarationRequest.authentication_method(:na)
          }
        }
        |> prepare_params()

      %{id: declaration_id, declaration_number: declaration_number} = insert(:il, :declaration_request, params)

      signed_declaration_request =
        data
        |> Map.put("seed", "some_current_hash")
        |> Map.put("declaration_number", declaration_number)

      drfo_signed_content(signed_declaration_request, tax_id)

      resp =
        conn
        |> Plug.Conn.put_req_header("drfo", tax_id)
        |> put_client_id_header(legal_entity_id)
        |> put_consumer_id_header(user_id)
        |> patch(declaration_request_path(conn, :sign, declaration_id), %{
          "signed_declaration_request" =>
            signed_declaration_request
            |> Jason.encode!()
            |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(200)

      assert get_in(resp, ~w(data status)) == "pending_verification"
    end
  end

  defp fixture_params do
    uuid = UUID.generate()

    %{
      data: %{
        id: UUID.generate(),
        start_date: "2017-03-02",
        end_date: "2017-03-02",
        person: %{
          id: UUID.generate(),
          first_name: "Петро",
          last_name: "Іванов",
          second_name: "Миколайович",
          birth_date: "1991-08-19",
          documents: [
            %{
              type: "PASSPORT",
              number: "120518"
            }
          ],
          confidant_person: [
            %{
              relation_type: "PRIMARY",
              first_name: "Іван",
              last_name: "Петров",
              second_name: "Миколайович",
              birth_date: "1991-08-20",
              birth_country: "Україна",
              birth_settlement: "Вінниця",
              gender: "MALE",
              tax_id: "2222222225",
              documents_person: [
                %{
                  type: "PASSPORT",
                  number: "120518"
                }
              ],
              documents_relationship: [
                %{
                  type: "COURT_DECISION",
                  number: "120518"
                }
              ],
              phones: [
                %{
                  type: "MOBILE",
                  number: "+380503410870"
                }
              ]
            }
          ]
        },
        employee: %{
          id: UUID.generate(),
          position: "P6",
          party: %{
            id: UUID.generate(),
            first_name: "Петро",
            last_name: "Іванов",
            second_name: "Миколайович",
            email: "email@example.com",
            phones: [
              %{
                type: "MOBILE",
                number: "+380503410870"
              }
            ],
            tax_id: "12345678"
          }
        },
        legal_entity: %{
          id: UUID.generate(),
          name: "Клініка Борис",
          short_name: "Борис",
          legal_form: "140",
          edrpou: "5432345432"
        },
        division: %{
          id: UUID.generate(),
          name: "Бориспільське відділення Клініки Борис",
          type: "CLINIC",
          status: "NEW"
        }
      },
      status: "NEW",
      inserted_by: uuid,
      updated_by: uuid,
      authentication_method_current: %{"type" => "NA"},
      printout_content: "",
      declaration_id: UUID.generate(),
      channel: DeclarationRequest.channel(:mis),
      declaration_number: NumberGenerator.generate(1, 2)
    }
  end

  defp assert_count_declaration_request_list(resp, count \\ 0) do
    assert_list_response_schema(resp["data"], "declaration_request")

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp, "paging")
    assert is_list(resp["data"])
    assert count == length(resp["data"])
  end

  defp get_person do
    %{
      tax_id: "3378115538",
      secret: "secret",
      second_name: "TestQOA",
      process_disclosure_data_consent: true,
      phones: [
        %{
          type: "MOBILE",
          number: "+380955947998"
        }
      ],
      patient_signed: true,
      last_name: "TestQOA",
      gender: "MALE",
      first_name: "TestQOA",
      emergency_contact: %{
        second_name: "Миколайович",
        phones: [
          %{
            type: "MOBILE",
            number: "+380503410870"
          }
        ],
        last_name: "Іванов",
        first_name: "Петро"
      },
      email: "qq2234562qq@gmail.com",
      documents: [
        %{
          type: "PASSPORT",
          number: "120518"
        }
      ],
      confidant_person: [
        %{
          tax_id: "3378115538",
          secret: "secret",
          second_name: "Миколайович",
          relation_type: "PRIMARY",
          phones: [
            %{
              type: "MOBILE",
              number: "+380503410870"
            }
          ],
          last_name: "Іванов",
          gender: "MALE",
          first_name: "Петро",
          documents_relationship: [
            %{
              type: "DOCUMENT",
              number: "120518"
            }
          ],
          documents_person: [
            %{
              type: "PASSPORT",
              number: "120518"
            }
          ],
          birth_settlement: "Вінниця",
          birth_date: "1991-08-19",
          birth_country: "Україна"
        },
        %{
          tax_id: "3378115538",
          secret: "secret",
          second_name: "Миколайович",
          relation_type: "SECONDARY",
          phones: [
            %{
              type: "MOBILE",
              number: "+380503410870"
            }
          ],
          last_name: "Іванов",
          gender: "MALE",
          first_name: "Петро",
          documents_relationship: [
            %{
              type: "DOCUMENT",
              number: "120518"
            }
          ],
          documents_person: [
            %{
              type: "PASSPORT",
              number: "120518"
            }
          ],
          birth_settlement: "Вінниця",
          birth_date: "1991-08-19",
          birth_country: "Україна"
        }
      ],
      birth_settlement: "Вінниця",
      birth_date: "2001-08-19",
      birth_country: "Україна",
      authentication_methods: [
        %{
          "type" => "OTP",
          "phone_number" => "+380955947998"
        }
      ],
      addresses: [
        %{
          zip: "02090",
          type: "REGISTRATION",
          street_type: "STREET",
          street: "Ніжинська",
          settlement_type: "CITY",
          settlement_id: "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
          settlement: "СОРОКИ-ЛЬВІВСЬКІ",
          region: "ПУСТОМИТІВСЬКИЙ",
          country: "UA",
          building: "15",
          area: "ЛЬВІВСЬКА",
          apartment: "23"
        },
        %{
          zip: "02090",
          type: "RESIDENCE",
          street_type: "STREET",
          street: "Ніжинська",
          settlement_type: "CITY",
          settlement_id: "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
          settlement: "СОРОКИ-ЛЬВІВСЬКІ",
          region: "ПУСТОМИТІВСЬКИЙ",
          country: "UA",
          building: "15",
          area: "ЛЬВІВСЬКА",
          apartment: "23"
        }
      ]
    }
  end

  defp employee_speciality(params) do
    Map.merge(
      %{
        "speciality" => "PEDIATRICIAN",
        "speciality_officio" => true,
        "level" => "Вища категорія",
        "qualification_type" => "Підтвердження",
        "attestation_name" => "random string",
        "attestation_date" => ~D[1987-04-17],
        "valid_to_date" => ~D[1987-04-17],
        "certificate_number" => "random string"
      },
      params
    )
  end

  defp prepare_params(params) when is_map(params) do
    data =
      params
      |> atomize_keys()
      |> Map.get(:data)

    start_date_year =
      data
      |> Map.get(:start_date)
      |> case do
        start_date when is_binary(start_date) ->
          start_date
          |> Date.from_iso8601!()
          |> Map.get(:year)

        _ ->
          nil
      end

    person_birth_date =
      data
      |> get_in(~w(person birth_date)a)
      |> case do
        birth_date when is_binary(birth_date) -> Date.from_iso8601!(birth_date)
        _ -> nil
      end

    Map.merge(params, %{
      data_legal_entity_id: get_in(data, ~w(legal_entity id)a),
      data_employee_id: get_in(data, ~w(employee id)a),
      data_start_date_year: start_date_year,
      data_person_tax_id: get_in(data, ~w(person tax_id)a),
      data_person_first_name: get_in(data, ~w(person first_name)a),
      data_person_last_name: get_in(data, ~w(person last_name)a),
      data_person_birth_date: person_birth_date
    })
  end

  def atomize_keys(nil), do: nil

  def atomize_keys(value) when is_map(value) do
    value
    |> Enum.map(fn {k, v} ->
      if is_binary(k) do
        {String.to_atom(k), atomize_keys(v)}
      else
        {k, atomize_keys(v)}
      end
    end)
    |> Enum.into(%{})
  end

  def atomize_keys(value) when is_list(value) do
    Enum.map(value, &atomize_keys/1)
  end

  def atomize_keys(value) do
    value
  end
end
