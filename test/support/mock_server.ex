defmodule EHealth.MockServer do
  @moduledoc false
  use Plug.Router

  alias EHealth.Utils.MapDeepMerge

  @inactive_legal_entity_id "356b4182-f9ce-4eda-b6af-43d2de8602aa"

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison
  plug :dispatch

  get "/ukr_med_registry" do
    ukr_med_registry =
      case conn.params do
        %{"edrpou" => "37367387"} -> [get_med_registry()]
        _ -> []
      end

    Plug.Conn.send_resp(conn, 200, Poison.encode!(%{"data" => ukr_med_registry}))
  end

  # Legal Entitity

  get "/legal_entities" do
    legal_entity =
      case conn.params do
        %{"edrpou" => "37367387", "type" => "MSP"} -> [get_legal_entity()]
        %{"edrpou" => "10002000", "type" => "MSP"} -> [get_legal_entity("356b4182-f9ce-4eda-b6af-43d2de8602aa", false)]
        _ -> []
      end

    Plug.Conn.send_resp(conn, 200, legal_entity |> wrap_response_with_paging() |> Poison.encode!())
  end

  post "/legal_entities" do
    legal_entity = MapDeepMerge.merge(get_legal_entity(conn.path_params["id"]), conn.body_params)
    Plug.Conn.send_resp(conn, 201, Poison.encode!(%{"data" => legal_entity}))
  end

  patch "/legal_entities/:id" do
    id = conn.path_params["id"]
    legal_entity =
      case id do
        @inactive_legal_entity_id -> get_legal_entity(id, false)
        _ -> get_legal_entity(id)
      end
    legal_entity = MapDeepMerge.merge(legal_entity, conn.body_params)
    Plug.Conn.send_resp(conn, 200, Poison.encode!(%{"data" => legal_entity}))
  end

  get "/legal_entities/:id" do
    case conn.path_params do
      %{"id" => "356b4182-f9ce-4eda-b6af-43d2de8602f2"} ->
        render_404(conn)
      %{"id" => "356b4182-f9ce-4eda-b6af-43d2de8602aa" = id} ->
        Plug.Conn.send_resp(conn, 200, id |> get_legal_entity(false) |> wrap_response() |> Poison.encode!())
      _ ->
        Plug.Conn.send_resp(conn, 200, get_legal_entity() |> wrap_response() |> Poison.encode!())
    end
  end

  # Party

  get "/party" do
    Plug.Conn.send_resp(conn, 200, [get_party()] |> wrap_response_with_paging() |> Poison.encode!())
  end

  post "/party" do
    party = MapDeepMerge.merge(get_party(), conn.body_params)
    Plug.Conn.send_resp(conn, 201, Poison.encode!(%{"data" => party}))
  end

  patch "/party/:id" do
    Plug.Conn.send_resp(conn, 200, Poison.encode!(%{"data" => get_party()}))
  end

  get "/party_users" do
    Plug.Conn.send_resp(conn, 200, [get_party_user()] |> wrap_response_with_paging() |> Poison.encode!())
  end

  post "/party_users" do
    user_party = MapDeepMerge.merge(get_party_user(), conn.body_params)
    Plug.Conn.send_resp(conn, 201, Poison.encode!(%{"data" => user_party}))
  end

  # Employee

  get "/employees" do
    employees =
      [get_employee(), get_employee()]
      |> wrap_response_with_paging()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, employees)
  end

  get "/employees/:id" do
    case conn.path_params do
      %{"id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"} ->
        Plug.Conn.send_resp(conn, 200, get_employee() |> wrap_response() |> Poison.encode!())
      _ -> render_404(conn)
    end
  end

  post "/employees" do
    employee = MapDeepMerge.merge(get_employee(), conn.body_params)
    case Map.get(employee, "updated_by") do
      nil ->
        resp =
          %{"error" => %{"invalid_validation" => "updated_by"}}
          |> wrap_response()
          |> Poison.encode!()
        Plug.Conn.send_resp(conn, 422, resp)

      _ -> Plug.Conn.send_resp(conn, 201, Poison.encode!(%{"data" => employee}))
    end

  end

  # Division

  get "/divisions/:id" do
    case conn.path_params do
      %{"id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"} ->
        Plug.Conn.send_resp(conn, 200, get_division() |> wrap_response() |> Poison.encode!())
      _ -> render_404(conn)
    end
  end

  # Mithril

  get "/admin/clients" do
    Plug.Conn.send_resp(conn, 200, [get_oauth_client()] |> wrap_response_with_paging() |> Poison.encode!())
  end

  get "/admin/users" do
    resp =
      conn.query_params
      |> get_oauth_users()
      |> wrap_response_with_paging()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  post "/admin/users" do
    resp =
      get_oauth_user()
      |> MapDeepMerge.merge(conn.body_params["user"])
      |> wrap_response(201)
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 201, resp)
  end

  put "/admin/clients/:id" do
    resp =
      conn.body_params["id"]
      |> get_oauth_client()
      |> MapDeepMerge.merge(conn.body_params["client"])
      |> wrap_response()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/admin/clients/:id" do
    resp =
      conn.path_params["id"]
      |> get_oauth_client()
      |> wrap_response()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/admin/roles" do
    resp =
      [get_oauth_role()]
      |> wrap_response_with_paging()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/admin/users/:id/roles" do
    resp =
      [get_oauth_user_role(conn.path_params["id"])]
      |> wrap_response_with_paging()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  post "/admin/users/:id/roles" do
    resp =
      conn.path_params["id"]
      |> get_oauth_user_role()
      |> wrap_response()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  # Ael

  put "signed_url_test" do
    Plug.Conn.send_resp(conn, 200, "http://example.com?signed_url=true")
  end

  # Man

  post "/templates/:id/actions/render" do
    Plug.Conn.send_resp(conn, 200, get_rendered_template())
  end

  def get_oauth_client(id \\ "f9bd4210-7c4b-40b6-957f-300829ad37dc") do
    %{
      "id" => id,
      "name" => "test",
      "type" => "client",
      "secret" => "some super secret",
      "redirect_uri" => "http =>//example.com/redirect_uri",
      "settings" => %{},
      "priv_settings" => %{},
      "redirect_uri" => "redirect_uri",
    }
  end

  def get_oauth_role do
    %{
      "id" => "f9bd4210-7c4b-40b6-957f-300829ad37dc",
      "name" => "DOCTOR",
      "scope" => "read"
    }
  end

  def get_oauth_user_role(user_id \\ "userid") do
    %{
      "id" => "7488a646-e31f-11e4-aace-600308960611",
      "user_id" => user_id,
      "role_id" => "f9bd4210-7c4b-40b6-957f-300829ad37dc",
      "client_id" => "f9bd4210-7c4b-40b6-957f-300829ad37dc",
    }
  end

  def get_oauth_user(id \\ "userid") do
    %{
      "id" => id,
      "settings" => %{},
      "email" => "mis_bot_1493831618@user.com",
      "type" => "user"
    }
  end

  def get_oauth_users(%{"email" => "test@user.com"}), do: [get_oauth_user()]
  def get_oauth_users(%{"email" => _}), do: []
  def get_oauth_users(_), do: [get_oauth_user()]

  def get_med_registry do
    %{
      "id" => "5432345432",
      "name" => "Клініка Борис",
      "edrpou" => "37367387",
      "inserted_at" => "1991-08-19T00.00.00.000Z",
      "inserted_by" => "userid",
      "updated_at" => "1991-08-19T00.00.00.000Z",
      "updated_by" => "userid"
    }
  end

  def get_employee do
    %{
      "id" => "7488a646-e31f-11e4-aace-600308960662",
      "employee_type" => "hr",
      "type" => "employee", # EView field
      "is_active" => true,
      "status" => "some status",
      "position" => "some position",
      "end_date" => "2011-04-17",
      "start_date" => "2010-04-17",
      "inserted_by" => "7488a646-e31f-11e4-aace-600308960662",
      "updated_by" => "7488a646-e31f-11e4-aace-600308960662"
    }
  end

  def get_division do
    %{
      "id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
      "legal_entity_id" => "d290f1ee-6c54-4b01-90e6-d701748f0851",
      "name" => "Бориспільське відділення Клініки Борис",
      "addresses" => [
        %{
          "type" => "REGISTRATION",
          "country" => "UA",
          "area" => "Житомирська",
          "region" => "Бердичівський",
          "settlement" => "Київ",
          "settlement_type" => "CITY",
          "settlement_id" => "43432432",
          "street_type" => "STREET",
          "street" => "вул. Ніжинська",
          "building" => "15",
          "apartment" => "23",
          "zip" => "02090"
        }
      ],
      "phones" => [
        %{
          "type" => "MOBILE",
          "number" => "+380503410870"
        }
      ],
      "email" => "email@example.com",
      "type" => "clinic",
      "external_id" => "3213213",
      "mountain_group" => "group1",
      "is_active" => true
    }
  end

  def get_party do
    %{
      "id" => "01981ab9-904c-4c36-88ab-959a94087483",
      "birth_date" => "1991-08-19",
      "first_name" => "Петро",
      "last_name" => "Іванов",
      "gender" => "MALE",
      "phones" => [
        %{"number" => "+380503410870", "type" => "MOBILE"}
       ],
      "documents" => [
        %{"number" => "120518", "type" => "PASSPORT"}
      ],
      "second_name" => "Миколайович",
      "tax_id" => "3126509816",
      "inserted_by" => "12a1c9e6-9fb8-4b22-b21c-250ee2155607",
      "updated_by" => "12a1c9e6-9fb8-4b22-b21c-250ee2155607"
    }
  end

  def get_party_user do
    %{
      "id" => "01981ab9-904c-4c36-88ab-959a94087483",
      "user_id" => "1cc91a5d-c02f-41e9-b571-1ea4f2375551",
      "party_id" => "01981ab9-904c-4c36-88ab-959a94087483",
    }
  end

  def get_legal_entity(id \\ "7cc91a5d-c02f-41e9-b571-1ea4f2375552", is_active \\ true) do
    %{
      "id" => id,
      "name" => "Клініка Борис",
      "short_name" => "Борис",
      "type" => "MSP",
      "edrpou" => "37367387",
      "addresses" => [
         %{
          "type" => "REGISTRATION",
          "country" => "UA",
          "area" => "Житомирська",
          "region" => "Бердичівський",
          "settlement" => "Київ",
          "settlement_type" => "CITY",
          "settlement_id" => "43432432",
          "street_type" => "STREET",
          "street" => "вул. Ніжинська",
          "building" => "15",
          "apartment" => "23",
          "zip" => "02090",
        }
      ],
      "phones" => [
         %{
          "type" => "MOBILE",
          "number" => "+380503410870"
        }
      ],
      "email" => "email@example.com",
      "is_active" => is_active,
      "public_name" => "Клініка Борис",
      "kveds" => [
        "86.01"
      ],
      "status" => "VERIFIED",
      "owner_property_type" => "state",
      "legal_form" => "ПІДПРИЄМЕЦЬ-ФІЗИЧНА ОСОБА",
      "medical_service_provider" => %{
        "licenses" => [
           %{
            "license_number" => "fd123443",
            "issued_by" => "Кваліфікацйна комісія",
            "issued_date" => "2017",
            "expiry_date" => "2017",
            "kved" => "86.01",
            "what_licensed" => "реалізація наркотичних засобів"
          }
        ],
        "accreditation" =>  %{
          "category" => "друга",
          "issued_date" => "2017",
          "expiry_date" => "2017",
          "order_no" => "fd123443",
          "order_date" => "2017"
        }
      },
      "inserted_at" => "1991-08-19T00.00.00.000Z",
      "inserted_by" => "userid",
      "updated_at" => "1991-08-19T00.00.00.000Z",
      "updated_by" => "userid"
    }
  end

  def get_rendered_template, do: "<html><body>Some template text</body></hrml>"

  def render(resource, conn, status) do
    conn = Plug.Conn.put_status(conn, status)
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, get_resp_body(resource, conn))
  end

  def render_404(conn) do
    "404.json"
    |> EView.Views.Error.render()
    |> render(conn, 404)
  end

  match _ do
    render_404(conn)
  end

  def get_resp_body(resource, conn), do: resource |> EView.wrap_body(conn) |> Poison.encode!()

  def wrap_response(data, code \\ 200) do
    %{
      "meta" => %{
        "code" => code,
        "type" => "list"
      },
      "data" => data
    }
  end

  def wrap_response_with_paging(data) do
    paging = %{
      "size" => nil,
      "limit" => 2,
      "has_more" => true,
      "cursors" => %{
        "starting_after" => "e9a3a1bb-da15-4f93-b414-1240af62ca51",
        "ending_before" => nil
      }
    }

    data
    |> wrap_response()
    |> Map.put("paging", paging)
  end
end
