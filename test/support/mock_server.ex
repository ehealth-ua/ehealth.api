defmodule EHealth.MockServer do
  @moduledoc false
  use Plug.Router

  alias EHealth.Utils.MapDeepMerge

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
        _ -> []
      end

    Plug.Conn.send_resp(conn, 200, legal_entity |> wrap_response_with_paging() |> Poison.encode!())
  end

  post "/legal_entities" do
    legal_entity = MapDeepMerge.merge(get_legal_entity(), conn.body_params)
    Plug.Conn.send_resp(conn, 201, Poison.encode!(%{"data" => legal_entity}))
  end

  patch "/legal_entities/:id" do
    case conn.path_params do
      %{"id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375552"} ->
        legal_entity = MapDeepMerge.merge(get_legal_entity(), conn.body_params)
        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{"data" => legal_entity}))
      _ -> render_404(conn)
    end
  end

  get "/legal_entities/:id" do
    case conn.path_params do
      %{"id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375552"} ->
        Plug.Conn.send_resp(conn, 200, get_legal_entity() |> wrap_response() |> Poison.encode!())
      _ -> render_404(conn)
    end
  end

  # Party

  get "/party" do
    Plug.Conn.send_resp(conn, 200, get_party() |> wrap_response_with_paging() |> Poison.encode!())
  end

  post "/party" do
    party = MapDeepMerge.merge(get_party(), conn.body_params)
    Plug.Conn.send_resp(conn, 201, Poison.encode!(%{"data" => party}))
  end

  patch "/party/:id" do
    Plug.Conn.send_resp(conn, 200, Poison.encode!(%{"data" => get_party()}))
  end

  # Employee

  post "/employees" do
    employee = MapDeepMerge.merge(get_employee(), conn.body_params)
    Plug.Conn.send_resp(conn, 201, Poison.encode!(%{"data" => employee}))
  end

  # OAuth
  post "/admin/clients" do
    client = %{
      "id": "f9bd4210-7c4b-40b6-957f-300829ad37dc",
      "name": "test",
      "type": "client",
      "client_id": "some id",
      "client_secret": "some super secret",
      "redirect_uri": "http://example.com/redirect_uri",
      "settings": %{},
      "priv_settings": %{},
      "redirect_uri": "redirect_uri",
    }
    Plug.Conn.send_resp(conn, 200, client |> wrap_response() |> Poison.encode!())
  end

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
      "end_date" => "2011-04-17T14:00:00.000000",
      "start_date" => "2010-04-17T14:00:00.000000",
      "inserted_by" => "7488a646-e31f-11e4-aace-600308960662",
      "updated_by" => "7488a646-e31f-11e4-aace-600308960662"
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

  def get_legal_entity do
    %{
      "id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375552",
      "name" => "Клініка Борис",
      "short_name" => "Борис",
      "type" => "MSP",
      "edrpou" => "37367387",
      "addresses" => [
         %{
          "type" => "RESIDENCE",
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
      "active" => true,
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

  def wrap_response(data) do
    %{
      "meta" => %{
        "code" => 200,
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
