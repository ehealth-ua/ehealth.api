defmodule EHealth.MockServer do
  @moduledoc false
  use Plug.Router

  alias EHealth.Utils.MapDeepMerge
  alias Ecto.UUID

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
    roles = case conn.path_params["id"] do
      "d0bde310-8401-11e7-bb31-be2e44b06b34" -> []
      _ -> [get_oauth_user_role(conn.path_params["id"], conn.query_params["client_id"])]
    end

    resp =
      roles
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

  # Digital signature

  post "/digital_signatures" do
    data =
      conn.body_params
      |> Map.get("signed_content")
      |> Base.decode64
    case data do
      :error ->
        data =
          %{"is_valid" => false}
          |> wrap_response()
          |> Poison.encode!
        Plug.Conn.send_resp(conn, 422, data)
      {:ok, data} ->
        data = %{
          "content" => Poison.decode!(data),
          "is_valid" => true,
          "signer" => %{
            "edrpou" => "37367387"
          }
        }
        |> wrap_response()
        |> Poison.encode!
        Plug.Conn.send_resp(conn, 200, data)
    end
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

        %{"person_id" => "585044f5-1272-4bca-8d41-8440eefe7d26"}
          -> {200, [get_declaration(nil, nil, nil, nil, "585044f5-1272-4bca-8d41-8440eefe7d26")]}

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
    render(get_person(id), conn, 200)
  end

  get "/persons" do
    render([get_person(), get_person()], conn, 200)
  end

  get "/all-persons" do
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
