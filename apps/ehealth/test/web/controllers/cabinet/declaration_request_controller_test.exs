defmodule EHealth.Web.Cabinet.DeclarationRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID
  alias EHealth.DeclarationRequests.DeclarationRequest

  setup :verify_on_exit!

  defmodule MithrilServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.get "/admin/clients/4d593e84-34dc-48d3-9e33-0628a8446956/details" do
      response =
        %{"client_type_name" => "CABINET"}
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/4d593e84-34dc-48d3-9e33-0628a8446956" do
      response =
        %{
          "id" => "4d593e84-34dc-48d3-9e33-0628a8446956",
          "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
          "block_reason" => nil,
          "email" => "email@example.com",
          "is_blocked" => false,
          "settings" => %{},
          "tax_id" => "12341234"
        }
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  @user_id "4d593e84-34dc-48d3-9e33-0628a8446956"
  @person_id "0c65d15b-32b4-4e82-b53d-0572416d890e"

  setup do
    register_mircoservices_for_tests([
      {MithrilServer, "OAUTH_ENDPOINT"}
    ])

    :ok
  end

  describe "declaration requests list via cabinet" do
    test "declaration requests list is successfully showed", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      declaration_request_in = insert(:il, :declaration_request, mpi_id: @person_id, data: fixture_params())
      declaration_request_out = insert(:il, :declaration_request, data: fixture_params())

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index))

      resp = json_response(conn, 200)

      declaration_request_ids = Enum.map(resp["data"], fn item -> Map.get(item, "id") end)
      assert declaration_request_in.id in declaration_request_ids
      refute declaration_request_out.id in declaration_request_ids

      schema =
        "specs/json_schemas/cabinet/declaration_requests_list.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "declaration requests list with search params", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      search_status = DeclarationRequest.status(:approved)
      search_start_year = "2018"

      declaration_request_in =
        insert(
          :il,
          :declaration_request,
          mpi_id: @person_id,
          status: search_status,
          data: fixture_params(%{"start_date" => "2018-03-02"})
        )

      declaration_request_out = insert(:il, :declaration_request, mpi_id: @person_id, data: fixture_params())

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index), %{status: search_status, start_year: search_start_year})

      resp = json_response(conn, 200)

      declaration_request_ids = Enum.map(resp["data"], fn item -> Map.get(item, "id") end)
      assert declaration_request_in.id in declaration_request_ids
      refute declaration_request_out.id in declaration_request_ids

      schema =
        "specs/json_schemas/cabinet/declaration_requests_list.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "declaration requests list ignore invalid search params", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      for _ <- 1..2, do: insert(:il, :declaration_request, mpi_id: @person_id, data: fixture_params())

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index), %{test: UUID.generate()})

      resp = json_response(conn, 200)
      assert length(resp["data"]) == 2

      schema =
        "specs/json_schemas/cabinet/declaration_requests_list.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "failed when person is not valid", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "11111111"})
      end)

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index))

      assert resp = json_response(conn, 401)
      assert %{"type" => "access_denied", "message" => "Person not found"} == resp["error"]
    end

    test "failed when user is blocked", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => true
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index))

      assert resp = json_response(conn, 401)
      assert %{"type" => "access_denied"} == resp["error"]
    end

    test "declaration requests list - expired status is not shown", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      declaration_request_in = insert(:il, :declaration_request, mpi_id: @person_id, data: fixture_params())

      declaration_request_out =
        insert(
          :il,
          :declaration_request,
          mpi_id: @person_id,
          status: DeclarationRequest.status(:expired),
          data: fixture_params()
        )

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index))

      resp = json_response(conn, 200)

      declaration_request_ids = Enum.map(resp["data"], fn item -> Map.get(item, "id") end)
      assert declaration_request_in.id in declaration_request_ids
      refute declaration_request_out.id in declaration_request_ids

      schema =
        "specs/json_schemas/cabinet/declaration_requests_list.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "declaration requests list with status search param - expired status means empty list", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      search_status = DeclarationRequest.status(:expired)
      search_start_year = "2018"

      insert(
        :il,
        :declaration_request,
        mpi_id: @person_id,
        status: search_status,
        data: fixture_params(%{"start_date" => "2018-03-02"})
      )

      insert(:il, :declaration_request, mpi_id: @person_id, data: fixture_params())

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index), %{status: search_status, start_year: search_start_year})

      resp = json_response(conn, 200)
      assert resp["data"] == []
    end
  end

  describe "declaration request details via cabinet" do
    test "declaration request details is successfully showed", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      %{id: employee_id} =
        insert(:prm, :employee, id: UUID.generate(), speciality: speciality(%{"speciality" => "PEDIATRICIAN"}))

      data =
        fixture_params()
        |> put_in(["employee", "id"], employee_id)

      %{id: declaration_request_id} = insert(:il, :declaration_request, mpi_id: @person_id, data: data)

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, declaration_request_id))

      assert %{
               "data" => %{
                 "seed" => "some_current_hash",
                 "employee" => %{
                   "speciality" => %{
                     "speciality" => "PEDIATRICIAN"
                   }
                 }
               }
             } = json_response(conn, 200)
    end

    test "declaration request is not found", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, UUID.generate()))

      resp = json_response(conn, 404)
      assert %{"error" => %{"type" => "not_found"}} = resp
    end

    test "failed when declaration request is not belong to person", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      %{id: declaration_request_id} = insert(:il, :declaration_request, data: fixture_params())

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, declaration_request_id))

      assert resp = json_response(conn, 403)
      assert %{"error" => %{"type" => "forbidden"}} = resp
    end

    test "failed when person is not valid", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "11111111"})
      end)

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, UUID.generate()))

      assert resp = json_response(conn, 401)
      assert %{"type" => "access_denied", "message" => "Person not found"} == resp["error"]
    end

    test "failed when user is blocked", %{conn: conn} do
      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => true
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{"tax_id" => "12341234"})
      end)

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, UUID.generate()))

      assert resp = json_response(conn, 401)
      assert %{"type" => "access_denied"} == resp["error"]
    end
  end

  describe "approve declaration_request" do
    test "success approve", %{conn: conn} do
      expect(MPIMock, :person, fn id, _headers ->
        mpi_get_person(id, 200, %{tax_id: "12341234"})
      end)

      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 10}}}
      end)

      declaration_request =
        insert(
          :il,
          :declaration_request,
          channel: DeclarationRequest.channel(:cabinet),
          mpi_id: "0c65d15b-32b4-4e82-b53d-0572416d890e"
        )

      insert(:prm, :employee, id: "d290f1ee-6c54-4b01-90e6-d701748f0851")

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> patch(cabinet_declaration_requests_path(conn, :approve, declaration_request.id))

      assert resp = json_response(conn, 200)
      assert DeclarationRequest.status(:approved) == resp["data"]["status"]
    end

    test "wrong channel", %{conn: conn} do
      declaration_request =
        insert(
          :il,
          :declaration_request,
          channel: DeclarationRequest.channel(:mis)
        )

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> patch(cabinet_declaration_requests_path(conn, :approve, declaration_request.id))

      assert resp = json_response(conn, 403)
      assert "Declaration request should be approved by Doctor" == resp["error"]["message"]
    end
  end

  defp mpi_get_person(id, response_status, params) do
    params = Map.put(params, :id, id)
    person = string_params_for(:person, params)

    {:ok, %{"data" => person, "meta" => %{"code" => response_status}}}
  end

  defp fixture_params(params \\ %{}) do
    %{
      "scope" => "family_doctor",
      "person" => %{
        "id" => UUID.generate(),
        "email" => nil,
        "gender" => "MALE",
        "secret" => "тЕСТдоК",
        "tax_id" => "3173108921",
        "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
        "addresses" => [
          %{
            "zip" => "21236",
            "area" => "АВТОНОМНА РЕСПУБЛІКА КРИМ",
            "type" => "RESIDENCE",
            "street" => "Тест",
            "country" => "UA",
            "building" => "1",
            "apartment" => "2",
            "settlement" => "ВОЛОШИНЕ",
            "street_type" => "STREET",
            "settlement_id" => UUID.generate(),
            "settlement_type" => "VILLAGE"
          },
          %{
            "zip" => "21236",
            "area" => "АВТОНОМНА РЕСПУБЛІКА КРИМ",
            "type" => "REGISTRATION",
            "street" => "Тест",
            "country" => "UA",
            "building" => "1",
            "apartment" => "2",
            "settlement" => "ВОЛОШИНЕ",
            "street_type" => "STREET",
            "settlement_id" => UUID.generate(),
            "settlement_type" => "VILLAGE"
          }
        ],
        "documents" => [%{"type" => "TEMPORARY_CERTIFICATE", "number" => "тт260656"}],
        "last_name" => "Петров",
        "birth_date" => "1991-08-20",
        "first_name" => "Іван",
        "second_name" => "Миколайович",
        "birth_country" => "Україна",
        "patient_signed" => false,
        "birth_settlement" => "Киев",
        "confidant_person" => [
          %{
            "gender" => "MALE",
            "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
            "secret" => "secret",
            "tax_id" => "3378115538",
            "last_name" => "Іванов",
            "birth_date" => "1991-08-19",
            "first_name" => "Петро",
            "second_name" => "Миколайович",
            "birth_country" => "Україна",
            "relation_type" => "PRIMARY",
            "birth_settlement" => "Вінниця",
            "documents_person" => [%{"type" => "PASSPORT", "number" => "120518"}],
            "documents_relationship" => [
              %{"type" => "COURT_DECISION", "number" => "120518"}
            ]
          },
          %{
            "gender" => "MALE",
            "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
            "secret" => "secret",
            "tax_id" => "3378115538",
            "last_name" => "Іванов",
            "birth_date" => "1991-08-19",
            "first_name" => "Петро",
            "second_name" => "Миколайович",
            "birth_country" => "Україна",
            "relation_type" => "SECONDARY",
            "birth_settlement" => "Вінниця",
            "documents_person" => [%{"type" => "PASSPORT", "number" => "120518"}],
            "documents_relationship" => [
              %{"type" => "COURT_DECISION", "number" => "120518"}
            ]
          }
        ],
        "emergency_contact" => %{
          "phones" => [%{"type" => "MOBILE", "number" => "+380686521488"}],
          "last_name" => "ТестДит",
          "first_name" => "ТестДит",
          "second_name" => "ТестДит"
        },
        "authentication_methods" => [%{"type" => "OFFLINE"}],
        "process_disclosure_data_consent" => true
      },
      "channel" => "MIS",
      "division" => %{
        "id" => UUID.generate(),
        "name" => "Бориспільське відділення Клініки Борис",
        "type" => "CLINIC",
        "status" => "ACTIVE",
        "email" => "example@gmail.com",
        "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
        "addresses" => [
          %{
            "zip" => "43000",
            "area" => "М.КИЇВ",
            "type" => "RESIDENCE",
            "street" => "Шевченка",
            "country" => "UA",
            "building" => "2",
            "apartment" => "23",
            "settlement" => "КИЇВ",
            "street_type" => "STREET",
            "settlement_id" => UUID.generate(),
            "settlement_type" => "CITY"
          }
        ],
        "external_id" => "3213213",
        "legal_entity_id" => UUID.generate()
      },
      "employee" => %{
        "id" => UUID.generate(),
        "party" => %{
          "id" => UUID.generate(),
          "email" => "example309@gmail.com",
          "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
          "tax_id" => "3033413670",
          "last_name" => "Іванов",
          "first_name" => "Петро",
          "second_name" => "Миколайович"
        },
        "position" => "P2",
        "status" => "APPROVED",
        "start_date" => "2017-03-02T10:45:16.000Z",
        "legal_entity_id" => UUID.generate()
      },
      "end_date" => "2068-06-12",
      "start_date" => "2018-06-12",
      "legal_entity" => %{
        "id" => UUID.generate(),
        "name" => "Клініка Лимич Медікал",
        "email" => "lymychcl@gmail.com",
        "edrpou" => "3160405192",
        "phones" => [%{"type" => "MOBILE", "number" => "+380979134223"}],
        "licenses" => [
          %{
            "order_no" => "К-123",
            "issued_by" => "Кваліфікацйна комісія",
            "expiry_date" => "1991-08-19",
            "issued_date" => "1991-08-19",
            "what_licensed" => "реалізація наркотичних засобів",
            "license_number" => "fd123443",
            "active_from_date" => "1991-08-19"
          }
        ],
        "addresses" => [
          %{
            "zip" => "02090",
            "area" => "ХАРКІВСЬКА",
            "type" => "REGISTRATION",
            "street" => "вул. Ніжинська",
            "country" => "UA",
            "building" => "15",
            "apartment" => "23",
            "settlement" => "ЧУГУЇВ",
            "street_type" => "STREET",
            "settlement_id" => UUID.generate(),
            "settlement_type" => "CITY"
          }
        ],
        "legal_form" => "140",
        "short_name" => "Лимич Медікал",
        "public_name" => "Лимич Медікал",
        "status" => "ACTIVE",
        "accreditation" => %{
          "category" => "FIRST",
          "order_no" => "fd123443",
          "order_date" => "1991-08-19",
          "expiry_date" => "1991-08-19",
          "issued_date" => "1991-08-19"
        }
      },
      "declaration_id" => UUID.generate(),
      "status" => "NEW"
    }
    |> Map.merge(params)
  end

  defp get_person(id, response_status, params) do
    params = Map.put(params, :id, id)
    person = string_params_for(:person, params)

    {:ok, %{"data" => person, "meta" => %{"code" => response_status}}}
  end

  def speciality(params \\ %{}) do
    %{
      "speciality" => Enum.random(doctor_specialities()),
      "speciality_officio" => true,
      "level" => Enum.random(doctor_levels()),
      "qualification_type" => Enum.random(doctor_qualification_types()),
      "attestation_name" => "random string",
      "attestation_date" => ~D[1987-04-17],
      "valid_to_date" => ~D[1987-04-17],
      "certificate_number" => "random string"
    }
    |> Map.merge(params)
  end

  defp doctor_specialities do
    [
      "THERAPIST",
      "PEDIATRICIAN",
      "FAMILY_DOCTOR"
    ]
  end

  defp doctor_levels do
    [
      "Друга категорія",
      "Перша категорія",
      "Вища категорія"
    ]
  end

  defp doctor_qualification_types do
    [
      "Присвоєння",
      "Підтвердження"
    ]
  end
end
