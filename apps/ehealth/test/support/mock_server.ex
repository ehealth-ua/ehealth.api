defmodule EHealth.MockServer do
  @moduledoc false
  use Plug.Router

  alias EHealth.Utils.MapDeepMerge
  alias Ecto.UUID
  alias EHealth.Utils.NumberGenerator

  @client_type_admin "356b4182-f9ce-4eda-b6af-43d2de8601a1"
  @client_type_nhs "b7d4d790-d427-4144-8607-f3892064c9e1"
  @client_type_mis "296da7d2-3c5a-4f6a-b8b2-631063737271"
  @client_type_nil "7cc91a5d-c02f-41e9-b571-1ea4f2375111"

  @user_for_role_1 "7cc91a5d-c02f-41e9-b571-1ea4f2375111"
  @user_for_role_2 "7cc91a5d-c02f-41e9-b571-1ea4f2375222"

  plug(:match)

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  def get_client_mis, do: @client_type_mis
  def get_client_nil, do: @client_type_nil
  def get_client_admin, do: @client_type_admin
  def get_client_nhs, do: @client_type_nhs

  def get_user_for_role_1, do: @user_for_role_1
  def get_user_for_role_2, do: @user_for_role_2

  # Mithril

  get "/admin/clients" do
    Plug.Conn.send_resp(
      conn,
      200,
      [get_oauth_client()] |> wrap_response_with_paging() |> Jason.encode!()
    )
  end

  patch "/admin/clients/:client_id/refresh_secret" do
    %{"client_id" => id} = conn.params

    resp =
      id
      |> get_oauth_client()
      |> wrap_response(200)
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/admin/users" do
    resp =
      conn.query_params
      |> get_oauth_users()
      |> wrap_response_with_paging()
      |> Jason.encode!()

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

  delete "/admin/tokens" do
    case conn.query_params do
      %{"user_ids" => @user_for_role_1 <> "," <> @user_for_role_2} -> render([], conn, 204)
      _ -> render_404(conn)
    end
  end

  get "/admin/users/:id" do
    resp =
      id
      |> get_oauth_user()
      |> wrap_response()
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  post "/admin/users" do
    resp =
      get_oauth_user()
      |> MapDeepMerge.merge(conn.body_params["user"])
      |> wrap_response(201)
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 201, resp)
  end

  put "/admin/clients/:id" do
    resp =
      conn.body_params["id"]
      |> get_oauth_client()
      |> MapDeepMerge.merge(conn.body_params["client"])
      |> wrap_response()
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/admin/clients/:id" do
    resp =
      conn.path_params["id"]
      |> get_oauth_client()
      |> wrap_response()
      |> Jason.encode!()

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
        @client_type_nhs -> "NHS"
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
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/admin/users/:id/roles" do
    roles =
      case conn.path_params["id"] do
        "d0bde310-8401-11e7-bb31-be2e44b06b34" -> []
        _ -> [get_oauth_user_role(conn.path_params["id"], conn.query_params["client_id"])]
      end

    resp =
      roles
      |> wrap_response()
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/admin/user_roles" do
    roles =
      case conn.query_params["user_ids"] do
        @user_for_role_1 <> "," <> @user_for_role_2 -> []
        _ -> [get_oauth_user_role(), get_oauth_user_role()]
      end

    resp =
      roles
      |> wrap_response()
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  post "/admin/users/:id/roles" do
    resp =
      conn.path_params["id"]
      |> get_oauth_user_role()
      |> wrap_response()
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  get "/admin/client_types" do
    client_type = get_client_type(conn.body_params)

    resp =
      [client_type]
      |> wrap_response()
      |> Jason.encode!()

    Plug.Conn.send_resp(conn, 200, resp)
  end

  # Digital signature

  post "/digital_signatures" do
    data =
      conn.body_params
      |> Map.get("signed_content")
      |> Base.decode64()

    case data do
      :error ->
        data =
          %{"is_valid" => false}
          |> wrap_response(422)
          |> Jason.encode!()

        Plug.Conn.send_resp(conn, 422, data)

      {:ok, data} ->
        content = Jason.decode!(data)

        data =
          %{
            "content" => Map.delete(content, "signer"),
            "is_valid" => true,
            "signer" => Map.get(content, "signer")
          }
          |> wrap_response()
          |> Jason.encode!()

        Plug.Conn.send_resp(conn, 200, data)
    end
  end

  def get_declaration("terminated") do
    nil |> get_declaration() |> Map.put("status", "terminated")
  end

  def get_declaration(
        id \\ nil,
        legal_entity_id \\ nil,
        division_id \\ nil,
        employee_id \\ nil,
        person_id \\ nil
      ) do
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
      "reason" => nil,
      "reason_description" => nil,
      "scope" => "declarations:read",
      "declaration_request_id" => UUID.generate(),
      "authentication_methods" => [
        %{"type" => "OTP", "phone_number" => "+380670000000"}
      ],
      "declaration_number" => NumberGenerator.generate(1, 2)
    }
  end

  def get_person(id \\ nil) do
    %{
      "id" => id || "156b4182-f9ce-4eda-b6af-43d2de8601z2",
      "version" => "default",
      "first_name" => "string value",
      "last_name" => "string value",
      "second_name" => "string value",
      "birth_date" => "1991-08-19",
      "birth_country" => "string value",
      "birth_settlement" => "string value",
      "gender" => "string value",
      "email" => "test@example.com",
      "tax_id" => "string value",
      "national_id" => "string value",
      "death_date" => "2091-08-19",
      "is_active" => true,
      "documents" => [],
      "addresses" => [],
      "phones" => [%{type: "MOBILE", number: "+380972526080"}],
      "secret" => "string value",
      "emergency_contact" => %{},
      "confidant_person" => [],
      "patient_signed" => true,
      "process_disclosure_data_consent" => true,
      "status" => "active",
      "inserted_by" => UUID.generate(),
      "updated_by" => UUID.generate(),
      "merged_ids" => [UUID.generate(), UUID.generate()],
      "authentication_methods" => [%{"type" => "OTP", "phone_number" => "+380955947998"}],
      "preferred_way_communication" => "––"
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
      "priv_settings" => %{}
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

  def get_oauth_user_role(
        user_id \\ "userid",
        client_id \\ "f9bd4210-7c4b-40b6-957f-300829ad37dc"
      ) do
    %{
      "id" => "7488a646-e31f-11e4-aace-600308960611",
      "user_id" => user_id,
      "role_id" => "f9bd4210-7c4b-40b6-957f-300829ad37dc",
      "client_id" => client_id,
      "role_name" => "some role",
      "client_name" => "some client"
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

  def get_oauth_users(%{
        "ids" => @user_for_role_1 <> "," <> @user_for_role_2,
        "is_blocked" => "true"
      }) do
    [get_oauth_user(@user_for_role_1), get_oauth_user(@user_for_role_1)]
  end

  def get_oauth_users(%{"email" => "test@user.com"}), do: [get_oauth_user()]
  def get_oauth_users(%{"email" => _}), do: []
  def get_oauth_users(_), do: [get_oauth_user()]

  def render(resource, conn, status) do
    conn = Plug.Conn.put_status(conn, status)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, get_resp_body(resource, conn))
  end

  def render_with_paging(resource, conn, paging \\ nil) do
    conn = Plug.Conn.put_status(conn, 200)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(
      200,
      resource
      |> wrap_response_with_paging(paging)
      |> Jason.encode!()
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

  def get_resp_body(resource, conn), do: resource |> EView.wrap_body(conn) |> Jason.encode!()

  def wrap_response(data, code \\ 200) do
    %{
      "meta" => %{
        "code" => code,
        "type" => "list"
      },
      "data" => data
    }
  end

  def wrap_object_response(data \\ %{}, code \\ 200) do
    %{
      "meta" => %{
        "code" => code
      },
      "data" => data
    }
  end

  def wrap_response_with_paging(data), do: wrap_response_with_paging(data, nil)

  def wrap_response_with_paging(data, nil) do
    wrap_response_with_paging(data, %{
      "page_number" => 1,
      "total_pages" => 1,
      "page_size" => 10,
      "total_entries" => Enum.count(data)
    })
  end

  def wrap_response_with_paging(data, paging) do
    data
    |> wrap_response()
    |> Map.put("paging", paging)
  end

  defp get_client_type(params) do
    Map.merge(%{"name" => "MSP", scope: ""}, params)
  end
end
