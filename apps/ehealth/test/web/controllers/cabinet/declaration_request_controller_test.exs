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
          data: fixture_params(%{start_date: "2018-03-02"})
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
  end

  defp fixture_params(params \\ %{}) do
    %{
      id: UUID.generate(),
      start_date: "2017-03-02",
      end_date: "2017-03-02",
      person: %{
        id: UUID.generate(),
        first_name: "Петро",
        last_name: "Іванов",
        second_name: "Миколайович",
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
        status: "ACTIVE"
      }
    }
    |> Map.merge(params)
  end

  defp get_person(id, response_status, params) do
    params = Map.put(params, :id, id)
    person = string_params_for(:person, params)

    {:ok, %{"data" => person, "meta" => %{"code" => response_status}}}
  end
end
