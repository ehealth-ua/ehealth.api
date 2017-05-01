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
