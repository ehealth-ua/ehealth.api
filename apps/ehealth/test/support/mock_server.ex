defmodule EHealth.MockServer do
  @moduledoc false
  use Plug.Router

  alias Ecto.UUID
  alias EHealth.Utils.NumberGenerator

  plug(:match)

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

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
end
