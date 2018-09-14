defmodule Mithril.Web.Auth.ClientControllerTest do
  use EHealth.Web.ConnCase

  import Mox
  alias Ecto.UUID

  setup :verify_on_exit!

  describe "get clients" do
    test "success", %{conn: conn} do
      msp()
      client_id = UUID.generate()

      expect(MithrilMock, :get_clients, fn params, _headers ->
        assert Map.has_key?(params, "id")
        assert client_id == params["id"]

        {:ok,
         %{
           "meta" => %{"code" => 200},
           "paging" => paging(),
           "data" => [
             client(UUID.generate()),
             client(UUID.generate())
           ]
         }}
      end)

      resp =
        conn
        |> put_client_id_header(client_id)
        |> get(client_path(conn, :index))
        |> json_response(200)
        |> assert_list_response_schema("auth", "clients")

      assert 2 == length(resp["data"])
      assert Map.has_key?(resp, "paging")
    end

    test "MIS can see only self-related clients", %{conn: conn} do
      mis()
      client_id = UUID.generate()

      expect(MithrilMock, :get_clients, fn params, _headers ->
        assert Map.has_key?(params, "id")
        assert client_id == params["id"]

        {:ok,
         %{
           "meta" => %{"code" => 200},
           "paging" => paging(),
           "data" => [
             client(UUID.generate())
           ]
         }}
      end)

      conn
      |> put_client_id_header(client_id)
      |> get(client_path(conn, :index))
      |> json_response(200)
      |> assert_list_response_schema("auth", "clients")
    end

    test "admin allowed to see all clients", %{conn: conn} do
      admin()
      client_id = UUID.generate()

      expect(MithrilMock, :get_clients, fn params, _headers ->
        refute Map.has_key?(params, "id")

        {:ok,
         %{
           "meta" => %{"code" => 200},
           "paging" => paging(),
           "data" => [
             client(UUID.generate()),
             client(UUID.generate())
           ]
         }}
      end)

      conn
      |> put_client_id_header(client_id)
      |> get(client_path(conn, :index))
      |> json_response(200)
      |> assert_list_response_schema("auth", "clients")
    end
  end

  describe "get client details" do
    test "success", %{conn: conn} do
      msp()
      client_id = UUID.generate()

      expect(MithrilMock, :get_client_details, fn client_id, _headers ->
        {:ok,
         %{
           "meta" => %{"code" => 200},
           "data" => client(client_id)
         }}
      end)

      data =
        conn
        |> put_client_id_header(client_id)
        |> get(client_path(conn, :show, client_id))
        |> json_response(200)
        |> assert_show_response_schema("auth", "client")
        |> Map.get("data")

      assert client_id == data["id"]
    end

    test "client not found", %{conn: conn} do
      msp()
      client_id = UUID.generate()
      expect(MithrilMock, :get_client_details, fn _, _ -> {:error, :not_found} end)

      assert %{"error" => %{"type" => "not_found"}} =
               conn
               |> put_client_id_header(client_id)
               |> get(client_path(conn, :show, client_id))
               |> json_response(404)
    end

    test "MSP client_id not allowed by context", %{conn: conn} do
      msp()

      conn
      |> put_client_id_header(UUID.generate())
      |> get(client_path(conn, :show, UUID.generate()))
      |> json_response(403)
    end

    test "MIS client_id not allowed by context", %{conn: conn} do
      mis()

      conn
      |> put_client_id_header(UUID.generate())
      |> get(client_path(conn, :show, UUID.generate()))
      |> json_response(403)
    end

    test "admin allowed to see any client details", %{conn: conn} do
      admin()

      expect(MithrilMock, :get_client_details, fn client_id, _headers ->
        {:ok,
         %{
           "meta" => %{"code" => 200},
           "data" => client(client_id)
         }}
      end)

      conn
      |> put_client_id_header(UUID.generate())
      |> get(client_path(conn, :show, UUID.generate()))
      |> json_response(200)
    end
  end

  defp client(id) do
    %{
      "id" => id,
      "name" => "Some client",
      "settings" => %{},
      "is_blocked" => false,
      "block_reason" => "",
      "user_id" => UUID.generate(),
      "client_type_id" => UUID.generate(),
      "client_type_name" => "MSP",
      "inserted_at" => DateTime.utc_now(),
      "updated_at" => DateTime.utc_now()
    }
  end

  defp paging do
    %{
      "page_number" => 2,
      "page_size" => 1,
      "total_entries" => 2,
      "total_pages" => 2
    }
  end
end
