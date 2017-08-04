defmodule EHealth.MockServer do
  @moduledoc false
  use Plug.Router

  alias EHealth.Utils.MapDeepMerge
  alias Ecto.UUID
  import EHealth.Utils.Connection

  @inactive_legal_entity_id "356b4182-f9ce-4eda-b6af-43d2de8602aa"
  @client_type_admin "356b4182-f9ce-4eda-b6af-43d2de8601a1"
  @client_type_mis "296da7d2-3c5a-4f6a-b8b2-631063737271"
  @client_type_nil "7cc91a5d-c02f-41e9-b571-1ea4f2375111"

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison
  plug :dispatch

  def get_client_mis, do: @client_type_mis
  def get_client_nil, do: @client_type_nil
  def get_client_admin, do: @client_type_admin

  # Legal Entitity

  get "/legal_entities" do
    legal_entity =
      case conn.params do
        %{"ids" => _} -> [get_legal_entity()]
        %{"id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375552"} -> [get_legal_entity()]
        %{"id" => "0d26d826-6241-11e7-907b-a6006ad3dba0"} -> [get_legal_entity()]
        %{"edrpou" => "37367387", "type" => "MSP"} -> [get_legal_entity()]
        %{"edrpou" => "10002000", "type" => "MSP"} -> [get_legal_entity("356b4182-f9ce-4eda-b6af-43d2de8602aa", false)]
        %{"edrpou" => "37367387", "is_active" => "true"} ->
          case get_client_id(conn.req_headers) do
            @client_type_admin -> [get_legal_entity(), get_legal_entity(), get_legal_entity()]
            _ ->                  [get_legal_entity()]
          end
        %{"id" => "8ea6d4d8-6240-11e7-907b-a6006ad3dba0"} ->
          [get_legal_entity("8ea6d4d8-6240-11e7-907b-a6006ad3dba0", false)]

        %{"id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9a8a"} ->
          [get_legal_entity("b075f148-7f93-4fc2-b2ec-2d81b19a9a8a", false, "CLOSED")]
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
    id
    |> case do
         @inactive_legal_entity_id -> get_legal_entity(id, false)
         _ -> get_legal_entity(id)
       end
    |> MapDeepMerge.merge(conn.body_params)
    |> render(conn, 200)
  end

  get "/legal_entities/:id" do
    case conn.path_params do
      %{"id" => "356b4182-f9ce-4eda-b6af-43d2de8602f2"} ->
        render_404(conn)
      %{"id" => "9b452d44-62f8-11e7-907b-a6006ad3dba0"} ->
        legal_entity = get_legal_entity()
        |> Map.merge(%{
          "mis_verified" => "NOT_VERIFIED",
          "nhs_verified" => true
        })
        Plug.Conn.send_resp(conn, 200, legal_entity |> wrap_response() |> Poison.encode!())
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

  get "/party/:id" do
    case conn.path_params["id"] do
      "01981ab9-904c-4c36-88ab-959a94087483" -> render(get_party(), conn, 200)
      "b63d802f-5225-4362-bc93-a8bba6eac167" -> render(get_party(), conn, 200)

      _ -> render_404(conn)
    end
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
    legal_entity_id = Map.get(conn.params, "legal_entity_id")
    expand = Map.has_key?(conn.params, "expand")
    tax_id = Map.get(conn.params, "tax_id")
    edrpou = Map.get(conn.params, "edrpou")
    status = Map.get(conn.params, "status")
    is_active = Map.get(conn.params, "is_active")
    starting_after = Map.get(conn.params, "starting_after")

    employees = cond do
      tax_id || edrpou ->
        [get_employee(legal_entity_id, expand, tax_id, edrpou)] |> Enum.filter(&(!is_nil(&1)))
      status == "APPROVED" && is_active == "true" ->
        [get_employee_by_id("0d26d826-6241-11e7-907b-a6006ad3dba0", legal_entity_id)]
      true ->
        employee = get_employee(legal_entity_id, expand)
        [employee, employee]
    end

    render_with_paging(employees, conn, starting_after)
  end

  get "/employees/:id" do
    case conn.path_params do
      %{"id" => "0d26d826-6241-11e7-907b-a6006ad3dba0"} ->
        render(get_employee("0d26d826-6241-11e7-907b-a6006ad3dba0"), conn, 200)

      %{"id" => "7488a646-e31f-11e4-aace-600308960662"} ->
        render(get_employee(), conn, 200)

      %{"id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"} ->
        render(get_employee(), conn, 200)

      %{"id" => "2497b2ac-662c-11e7-907b-a6006ad3dba0"} ->
        "0d26d826-6241-11e7-907b-a6006ad3dba0"
        |> get_employee("b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", "3067305998", nil)
        |> render(conn, 200)

      %{"id" => "6bbdb29e-6627-11e7-907b-a6006ad3dba0"} ->
        "0d26d826-6241-11e7-907b-a6006ad3dba0"
        |> get_employee("b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", "3067305998", nil)
        |> Map.put("employee_type", "DOCTOR")
        |> render(conn, 200)

      %{"id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9a8a"} ->
        get_employee()
        |> Map.merge(%{"status" => "NEW", "is_active" => true})
        |> render(conn, 200)

      %{"id" => "b075f148-7f93-4fc2-b2ec-2d81b19a91a1"} ->
        get_employee()
        |> Map.merge(%{"status" => "APPROVED", "is_active" => false})
        |> render(conn, 200)

      %{"id" => "d9a908d8-6895-11e7-907b-a6006ad3dba0"} ->
        get_employee()
        |> Map.merge(%{"employee_type" => "ADMIN", "status" => "DISMISSED", "is_active" => true})
        |> render(conn, 200)

      %{"id" => "b075f148-7f93-4fc2-b2ec-2d81b19a911a"} ->
        render(get_employee("7cc91a5d-c02f-41e9-b571-1ea4f2375552", nil, nil, nil), conn, 200)
      _ -> render_404(conn)
    end
  end

  patch "/employees/:id" do
    get_employee()
    |> MapDeepMerge.merge(conn.body_params)
    |> render(conn, 200)
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

  get "/divisions" do
    render_with_paging([get_division(), get_division()], conn)
  end

  get "/divisions/:id" do
    case conn.path_params["id"] do
      "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b" -> render(get_division(), conn, 200)

      _ -> render_404(conn)
    end
  end

  post "/divisions" do
    {code, resp} = case conn.body_params do
      %{"legal_entity_id" => _id} ->
        {201, MapDeepMerge.merge(get_division(), conn.body_params)}
      _ ->
        {422, %{"error" => %{"invalid_validation" => "legal_entity_id"}}}
    end

    render(resp, conn, code)
  end

  patch "/divisions/:id" do
    {code, resp} =
      case conn.path_params["id"] do
        "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b" ->
          {200, MapDeepMerge.merge(get_division(), conn.body_params)}
        _ ->
          {422, %{"error" => %{"invalid_validation" => "legal_entity_id"}}}
      end

    render(resp, conn, code)
  end

  patch "/divisions/actions/set_mountain_group" do
    {code, resp} =
      case conn.body_params["settlement_id"] do
        "b075f148-7f93-4fc2-b2ec-2d81b19a9b7a" ->
          {200, []}
        _ ->
          {422, %{"error" => %{"invalid_validation" => "legal_entity_id"}}}
      end

    render(resp, conn, code)
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

  delete "/admin/users/:id/roles" do
    case conn.query_params do
      %{"role_name" => _} -> render([], conn, 204)
      _ -> render_404(conn)
    end
  end

  delete "/admin/users/:id/apps" do
    case conn.query_params do
      %{"client_id" => _} -> render([], conn, 204)
      _ -> render_404(conn)
    end
    render([], conn, 204)
  end

  delete "/admin/users/:id/tokens" do
    case conn.query_params do
      %{"client_id" => _} -> render([], conn, 204)
      _ -> render_404(conn)
    end
  end

  get "/admin/users/:id" do
    resp =
      id
      |> get_oauth_user()
      |> wrap_response()
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

  get "/admin/clients/356b4182-f9ce-4eda-b6af-43d2de8603f3/details" do
    render_404(conn)
  end

  get "/admin/clients/:id/details" do
    id = conn.path_params["id"]
    client_type_name =
      case id do
        @client_type_mis -> "MIS"
        @client_type_admin -> "NHS ADMIN"
        @client_type_nil -> nil
        _ -> "MSP"
      end
    id
    |> get_oauth_client_details(client_type_name)
    |> render(conn, 200)
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
      [get_oauth_user_role(conn.path_params["id"], conn.query_params["client_id"])]
      |> wrap_response()
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
    Plug.Conn.send_resp(conn, 200, get_rendered_template(id, conn.body_params))
  end

  # UAddress

  get "/settlements" do
    conn.body_params
    |> case do
         %{"settlement_id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7a"} -> get_settlement("1")
         _ -> get_settlement()
       end
    |> List.wrap()
    |> render_with_paging(conn)
  end

  get "/settlements/:id" do
    resp =
      "1"
      |> get_settlement()
      |> wrap_response()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  patch "/settlements/:id" do
    conn.path_params["id"]
    |> get_settlement()
    |> MapDeepMerge.merge(conn.body_params["settlement"])
    |> render(conn, 200)
  end

  get "/regions/:id" do
    resp =
      get_region()
      |> wrap_response()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/districts/:id" do
    resp =
      get_district()
      |> wrap_response()
      |> Poison.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  # OTP Verification

  get "/verifications" do
    params =
      conn
      |> Plug.Conn.fetch_query_params(conn)
      |> Map.get(:params)

    response =
      params
      |> search_for_number
      |> wrap_response
      |> Poison.encode!

    Plug.Conn.send_resp(conn, 200, response)
  end

  # OPS
  get "/declarations/:id" do
    case conn.path_params["id"] do
      "156b4182-f9ce-4eda-b6af-43d2de8601z2" -> render(get_declaration(), conn, 200)
      _ -> render_404(conn)
    end
  end

  get "/declarations" do
    {code, resp} =
      case conn.params do
        %{"person_id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375200"}
          -> {200, [get_declaration(), get_declaration("terminated")]}

        %{"person_id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375400"}
          -> {200, [get_declaration(), get_declaration()]}

        %{"person_id" => _} -> {200, []}

        # MSP
        %{"legal_entity_id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375552"}
          -> {200, [get_declaration()]}

        # MIS
        %{"legal_entity_id" => "296da7d2-3c5a-4f6a-b8b2-631063737271"} ->
          {200, [get_declaration(), get_declaration()]}

        # NHS_Admin
        %{"legal_entity_id" => "356b4182-f9ce-4eda-b6af-43d2de8601a1"} ->
          {200, [get_declaration(), get_declaration(), get_declaration()]}

        _ -> {200, []}
      end
    render_with_paging(resp, conn, code)
  end

  patch "/employees/:id/declarations/actions/terminate" do
    case conn.params do
      %{"id" => _, "user_id" => _} -> render([], conn, 200)
      _ -> render([], conn, 404)
    end
  end

  # MPI
  get "/persons/:id" do
    render(get_person(), conn, 200)
  end

  get "/persons" do
    render([get_person(), get_person()], conn, 200)
  end

  def get_declaration("terminated") do
    nil |> get_declaration() |> Map.put("status", "terminated")
  end

  def get_declaration(id \\ nil, legal_entity_id \\ nil, division_id \\ nil, employee_id \\ nil, person_id \\ nil) do
    %{
        "id" => id || "156b4182-f9ce-4eda-b6af-43d2de8601z2",
        "legal_entity_id" => legal_entity_id || "7cc91a5d-c02f-41e9-b571-1ea4f2375552",
        "division_id" => division_id || "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        "employee_id" => employee_id || "7488a646-e31f-11e4-aace-600308960662",
        "person_id" => person_id || "156b4182-f9ce-4eda-b6af-43d2de8601z2",
        "start_date" => "2010-08-19 00:00:00",
        "end_date" => "2010-08-19 00:00:00",
        "status" => "active",
        "signed_at" => "2010-08-19 00:00:00",
        "created_by" => UUID.generate(),
        "updated_by" => UUID.generate(),
        "is_active" => false,
        "scope" => "declarations:read",
        "declaration_request_id" => UUID.generate()
    }
  end

  def get_person(id \\ nil) do
    %{
      "id" => id || "156b4182-f9ce-4eda-b6af-43d2de8601z2",
      "version" => "default",
      "first_name" => "string value",
      "last_name" => "string value",
      "second_name" => "string value",
      "birth_date" => "1991-08-19T00.00.00.000Z",
      "birth_country" => "string value",
      "birth_settlement" => "string value",
      "gender" => "string value",
      "email" => "string value",
      "tax_id" => "string value",
      "national_id" => "string value",
      "death_date" => "1991-08-19T00.00.00.000Z",
      "is_active" => true,
      "documents" => %{},
      "addresses" => %{},
      "phones" => %{},
      "secret" => "string value",
      "emergency_contact" => %{},
      "confidant_person" => %{},
      "patient_signed" => true,
      "process_disclosure_data_consent" => true,
      "status" => "active",
      "inserted_by" => UUID.generate(),
      "updated_by" => UUID.generate(),
      "authentication_methods" => %{},
      "merged_ids" => [UUID.generate(), UUID.generate()]
    }
  end

  def search_for_number(params) do
    case params do
      %{ "number" => "+380508887700", "statuses" => "completed" } -> [1]
      _ -> []
    end
  end

  def get_settlement(mountain_group \\ "0") do
    %{
      "id": "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
      "region_id": "18981558-ff6c-4b35-9d5f-001848f98987",
      "district_id": "46dbf26a-2cd2-43fe-a592-c4f3c85e6d6a",
      "name": "Київ",
      "mountain_group": mountain_group
    }
  end

  def get_region do
    %{
      "id": "7e060885-6982-48fe-870c-8ccbee8744ba",
      "name": "Житомирська"
    }
  end

  def get_district do
    %{
      "id": "ed183157-e12b-4dda-aa1a-6cc5118905b2",
      "name": "Бердичівський"
    }
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
    }
  end

  def get_oauth_client_details(id, client_type_name) do
    %{
      "id" => id,
      "client_type_name" => client_type_name
    }
  end

  def get_oauth_role do
    %{
      "id" => "f9bd4210-7c4b-40b6-957f-300829ad37dc",
      "name" => "DOCTOR",
      "scope" => "read"
    }
  end

  def get_oauth_user_role(user_id \\ "userid", client_id \\ "f9bd4210-7c4b-40b6-957f-300829ad37dc") do
    %{
      "id" => "7488a646-e31f-11e4-aace-600308960611",
      "user_id" => user_id,
      "role_id" => "f9bd4210-7c4b-40b6-957f-300829ad37dc",
      "client_id" => client_id,
      "role_name" => "some role",
      "client_name" => "some client",
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

  def get_employee_by_id(id, legal_entity_id) do
    legal_entity_id
    |> get_employee()
    |> Map.put("id", id)
  end

  def get_employee do
    get_employee("7cc91a5d-c02f-41e9-b571-1ea4f2375552", "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", nil, "38782323")
  end

  def get_employee(legal_entity_id) do
    get_employee(legal_entity_id, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", nil, "38782323")
  end

  def get_employee(legal_entity_id, _expand = false), do: get_employee(legal_entity_id)

  def get_employee(legal_entity_id, _expand = true) do
    legal_entity_id
    |> get_employee()
    |> Map.merge(%{
         "party" => get_party_short(),
         "division" => get_division_short(),
         "legal_entity" => get_legal_entity_short(legal_entity_id),
       })
  end

  def get_employee(_, _, _, ""), do: nil

  def get_employee(_, _, "", _), do: nil

  def get_employee(legal_entity_id, division_id, tax_id, edrpou) do
    %{
      "id" => "7488a646-e31f-11e4-aace-600308960662",
      "legal_entity_id" => legal_entity_id,
      "division_id" => division_id,
      "updated_by" => "e8119d87-2d48-48c2-915c-1d3a1b25b16b",
      "status" => "APPROVED",
      "start_date" => "2017-03-02",
      "position" => "P1",
      "party_id" => "b63d802f-5225-4362-bc93-a8bba6eac167",
      "party" => %{
        "second_name" => "Миколайович",
        "last_name" => "Іванов",
        "id" => "b63d802f-5225-4362-bc93-a8bba6eac167",
        "first_name" => "Петро",
        "tax_id": tax_id,
      },
      "legal_entity" => %{
        "type" => "MSP",
        "status" => "ACTIVE",
        "mis_verified" => "NOT_VERIFIED",
        "nhs_verified" => false,
        "short_name" => "Адоніс22",
        "public_name" => "Адоніс22",
        "owner_property_type" => "STATE",
        "name" => "Клініка Адоніс22",
        "legal_form" => "140",
        "id" => legal_entity_id,
        "edrpou" => edrpou
      },
      "is_active" => true,
      "inserted_by" => "e8119d87-2d48-48c2-915c-1d3a1b25b16b",
      "end_date" => nil,
      "employee_type" => "OWNER",
      "doctor" => %{
        "id" => "e8119d87-2d48-48c2-915c-1d3a1b25b16b",
        "specialities" => [
          %{
            "valid_to_date" => "2017-08-05",
            "speciality_officio" => true,
            "speciality" => "PEDIATRICIAN",
            "qualification_type" => "AWARDING",
            "level" => "FIRST",
            "certificate_number" => "AB/21331",
            "attestation_name" => "Академія Богомольця",
            "attestation_date" => "2017-08-05"
          }
        ],
        "science_degree" => %{
          "speciality" => "THERAPIST",
          "issued_date" => "2017-08-05",
          "institution_name" => "Академія Богомольця",
          "diploma_number" => "DD123543",
          "degree" => "Доктор філософії",
          "country" => "UA",
          "city" => "Київ"
        },
        "qualifications" => [
          %{
            "type" => "AWARDING",
            "speciality" => "Педіатр",
            "issued_date" => "2017-08-05",
            "institution_name" => "Академія Богомольця",
            "certificate_number" => "2017-08-05"
          }
        ],
        "educations" => [
          %{
            "speciality" => "Педіатр",
            "issued_date" => "2017-08-05",
            "institution_name" => "Академія Богомольця",
            "diploma_number" => "DD123543",
            "degree" => "MASTER",
            "country" => "UA",
            "city" => "Київ"
          }
        ]
      },
    }
  end

  def get_division_short do
    %{
      "id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
      "legal_entity_id" => "d290f1ee-6c54-4b01-90e6-d701748f0851",
      "name" => "Бориспільське відділення Клініки Борис",
      "mountain_group" => "yes"
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
      "location" => %{
        "longitude" => 30.45000,
        "latitude" => 50.52333
      },
      "email" => "email@example.com",
      "type" => "CLINIC",
      "external_id" => "3213213",
      "mountain_group" => "group1",
      "status" => "ACTIVE"
    }
  end

  def get_party_short do
    %{
      "id" => "01981ab9-904c-4c36-88ab-959a94087483",
      "first_name" => "Петро",
      "last_name" => "Іванов",
      "second_name" => "Іванович",
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
      "updated_by" => "12a1c9e6-9fb8-4b22-b21c-250ee2155607",
      "users" => []
    }
  end

  def get_party_user do
    %{
      "id" => "01981ab9-904c-4c36-88ab-959a94087483",
      "user_id" => "1cc91a5d-c02f-41e9-b571-1ea4f2375551",
      "party_id" => "01981ab9-904c-4c36-88ab-959a94087483",
    }
  end

  def get_legal_entity_short(id \\ "7cc91a5d-c02f-41e9-b571-1ea4f2375552") do
    %{
      "id" => id,
      "name" => "Клініка Борис",
      "short_name" => "Борис",
      "public_name" => "Борис",
      "type" => "MSP",
      "edrpou" => "37367387",
      "status" => "ACTIVE",
      "mis_verified" => "VERIFIED",
      "nhs_verified" => false,
      "owner_property_type" => "state",
      "legal_form" => "ПІДПРИЄМЕЦЬ-ФІЗИЧНА ОСОБА",
    }
  end

  def get_legal_entity(id \\ "7cc91a5d-c02f-41e9-b571-1ea4f2375552", is_active \\ true, status \\ "ACTIVE") do
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
      "mis_verified" => "VERIFIED",
      "nhs_verified" => false,
      "public_name" => "Клініка Борис",
      "kveds" => [
        "86.01"
      ],
      "status" => status,
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
      "updated_by" => "userid",
      "created_by_mis_client_id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
    }
  end

  def get_rendered_template("32", params) do
    "<html><body>Printout form for declaration request ##{params["id"]}</body></html>"
  end

  def get_rendered_template(_, _), do: "<html><body>Some template text</body></html>"

  def render(resource, conn, status) do
    conn = Plug.Conn.put_status(conn, status)
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, get_resp_body(resource, conn))
  end

  def render_with_paging(resource, conn, starting_after \\ nil) do
    conn = Plug.Conn.put_status(conn, 200)
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200,
      resource
      |> wrap_response_with_paging(starting_after)
      |> Poison.encode!()
    )
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

  def wrap_response_with_paging(data, nil), do: wrap_response_with_paging(data)

  @doc """
  Returns second page which is the last one
  """
  def wrap_response_with_paging(data, _starting_after) do
    paging = %{
      "size" => nil,
      "limit" => 2,
      "has_more" => false,
      "cursors" => %{
        "starting_after" => nil,
        "ending_before" => "e9a3a1bb-da15-4f93-b414-1240af62ca51"
      }
    }

    data
    |> wrap_response()
    |> Map.put("paging", paging)
  end

  @doc """
  Returns first page
  """
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
