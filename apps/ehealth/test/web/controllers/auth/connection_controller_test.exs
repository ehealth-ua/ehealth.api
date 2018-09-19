defmodule Mithril.Web.Auth.ConnectionControllerTest do
  use EHealth.Web.ConnCase

  import Mox
  alias Ecto.UUID

  setup :verify_on_exit!

  describe "refresh client secret" do
    test "success refresh client secret", %{conn: conn} do
      client_id = UUID.generate()
      connection_id = UUID.generate()
      msp()

      expect(MithrilMock, :refresh_connection_secret, fn client_id, connection_id, _ ->
        {:ok,
         %{
           "meta" => %{"code" => 200},
           "data" => connection(client_id, connection_id)
         }}
      end)

      data =
        conn
        |> put_client_id_header(client_id)
        |> patch(client_connection_path(conn, :refresh_secret, client_id, connection_id))
        |> json_response(200)
        |> assert_show_response_schema("auth", "connection_with_secret")
        |> Map.get("data")

      assert connection_id == data["id"]
      assert client_id == data["client_id"]
      assert "some-secret" == data["secret"]
    end

    test "connection not found", %{conn: conn} do
      msp()
      client_id = UUID.generate()
      expect(MithrilMock, :refresh_connection_secret, fn _, _, _ -> {:error, :not_found} end)

      assert %{"error" => %{"type" => "not_found"}} =
               conn
               |> put_client_id_header(client_id)
               |> patch(client_connection_path(conn, :refresh_secret, client_id, UUID.generate()))
               |> json_response(404)
    end

    test "admin allowed to refresh anybody secret", %{conn: conn} do
      admin()
      client_id = UUID.generate()
      connection_id = UUID.generate()

      expect(MithrilMock, :refresh_connection_secret, fn client_id, connection_id, _ ->
        {:ok,
         %{
           "meta" => %{"code" => 200},
           "data" => connection(client_id, connection_id)
         }}
      end)

      conn
      |> put_client_id_header(client_id)
      |> patch(client_connection_path(conn, :refresh_secret, client_id, connection_id))
      |> json_response(200)
    end
  end

  describe "get connections" do
    test "success", %{conn: conn} do
      msp()
      client_id = UUID.generate()

      expect(MithrilMock, :get_client_connections, fn client_id, _, _headers ->
        {:ok,
         %{
           "meta" => %{"code" => 200},
           "paging" => paging(),
           "data" => [
             connection(client_id, UUID.generate()),
             connection(client_id, UUID.generate())
           ]
         }}
      end)

      data =
        conn
        |> put_client_id_header(client_id)
        |> get(client_connection_path(conn, :index, client_id))
        |> json_response(200)
        |> assert_list_response_schema("auth", "connections")
        |> Map.get("data")

      assert 2 == length(data)
    end
  end

  describe "get connection details" do
    test "success", %{conn: conn} do
      msp()
      client_id = UUID.generate()
      connection_id = UUID.generate()

      expect(MithrilMock, :get_client_connection, fn client_id, connection_id, _headers ->
        {:ok,
         %{
           "meta" => %{"code" => 200},
           "data" => connection(client_id, connection_id)
         }}
      end)

      data =
        conn
        |> put_client_id_header(client_id)
        |> get(client_connection_path(conn, :show, client_id, connection_id))
        |> json_response(200)
        |> assert_show_response_schema("auth", "connection")
        |> Map.get("data")

      assert connection_id == data["id"]
      assert client_id == data["client_id"]
      refute Map.has_key?(data, "secret")
    end

    test "connection not found", %{conn: conn} do
      msp()
      client_id = UUID.generate()
      expect(MithrilMock, :get_client_connection, fn _, _, _ -> {:error, :not_found} end)

      assert %{"error" => %{"type" => "not_found"}} =
               conn
               |> put_client_id_header(client_id)
               |> get(client_connection_path(conn, :show, client_id, UUID.generate()))
               |> json_response(404)
    end
  end

  describe "update connection" do
    test "success", %{conn: conn} do
      msp()
      client_id = UUID.generate()
      connection_id = UUID.generate()
      params = %{"redirect_uri" => "https://example.com/redirect"}

      expect(MithrilMock, :update_client_connection, fn client_id, connection_id, attrs, _headers ->
        assert params["redirect_uri"] == attrs["redirect_uri"]

        {:ok,
         %{
           "meta" => %{"code" => 200},
           "data" => client_id |> connection(connection_id) |> Map.put("redirect_uri", attrs["redirect_uri"])
         }}
      end)

      data =
        conn
        |> put_client_id_header(client_id)
        |> patch(client_connection_path(conn, :update, client_id, connection_id, params))
        |> json_response(200)
        |> assert_show_response_schema("auth", "connection")
        |> Map.get("data")

      assert connection_id == data["id"]
      assert client_id == data["client_id"]
      assert params["redirect_uri"] == data["redirect_uri"]
      refute Map.has_key?(data, "secret")
    end

    test "connection not found", %{conn: conn} do
      msp()
      client_id = UUID.generate()
      expect(MithrilMock, :update_client_connection, fn _, _, _, _ -> {:error, :not_found} end)

      assert %{"error" => %{"type" => "not_found"}} =
               conn
               |> put_client_id_header(client_id)
               |> patch(
                 client_connection_path(conn, :update, client_id, UUID.generate(), %{
                   "redirect_uri" => "https://example.com"
                 })
               )
               |> json_response(404)
    end
  end

  describe "delete connection" do
    test "success", %{conn: conn} do
      msp()
      client_id = UUID.generate()
      connection_id = UUID.generate()

      expect(MithrilMock, :delete_client_connection, fn _client_id, _connection_id, _headers ->
        {:ok,
         %{
           "meta" => %{"code" => 204},
           "data" => ""
         }}
      end)

      conn
      |> put_client_id_header(client_id)
      |> delete(client_connection_path(conn, :delete, client_id, connection_id))
      |> response(204)
    end

    test "connection not found", %{conn: conn} do
      msp()
      client_id = UUID.generate()
      expect(MithrilMock, :delete_client_connection, fn _, _, _ -> {:error, :not_found} end)

      assert %{"error" => %{"type" => "not_found"}} =
               conn
               |> put_client_id_header(client_id)
               |> delete(client_connection_path(conn, :delete, client_id, UUID.generate()))
               |> json_response(404)
    end
  end

  describe "client_id not allowed by context for MSP" do
    test "refresh_secret", %{conn: conn} do
      msp()

      conn
      |> put_client_id_header(UUID.generate())
      |> patch(client_connection_path(conn, :refresh_secret, UUID.generate(), UUID.generate()))
      |> json_response(403)
    end

    test "show connections", %{conn: conn} do
      msp()

      conn
      |> put_client_id_header(UUID.generate())
      |> get(client_connection_path(conn, :index, UUID.generate()))
      |> json_response(403)
    end

    test "show connection details", %{conn: conn} do
      msp()

      conn
      |> put_client_id_header(UUID.generate())
      |> get(client_connection_path(conn, :show, UUID.generate(), UUID.generate()))
      |> json_response(403)
    end

    test "update connection", %{conn: conn} do
      msp()

      conn
      |> put_client_id_header(UUID.generate())
      |> patch(client_connection_path(conn, :update, UUID.generate(), UUID.generate(), %{}))
      |> json_response(403)
    end

    test "delete connection", %{conn: conn} do
      msp()

      conn
      |> put_client_id_header(UUID.generate())
      |> delete(client_connection_path(conn, :delete, UUID.generate(), UUID.generate()))
      |> json_response(403)
    end
  end

  describe "client_id not allowed by context for MIS" do
    test "refresh_secret", %{conn: conn} do
      mis()

      conn
      |> put_client_id_header(UUID.generate())
      |> patch(client_connection_path(conn, :refresh_secret, UUID.generate(), UUID.generate()))
      |> json_response(403)
    end

    test "show connections", %{conn: conn} do
      mis()

      conn
      |> put_client_id_header(UUID.generate())
      |> get(client_connection_path(conn, :index, UUID.generate()))
      |> json_response(403)
    end

    test "show connection details", %{conn: conn} do
      mis()

      conn
      |> put_client_id_header(UUID.generate())
      |> get(client_connection_path(conn, :show, UUID.generate(), UUID.generate()))
      |> json_response(403)
    end

    test "update connection", %{conn: conn} do
      mis()

      conn
      |> put_client_id_header(UUID.generate())
      |> patch(client_connection_path(conn, :update, UUID.generate(), UUID.generate(), %{}))
      |> json_response(403)
    end

    test "delete connection", %{conn: conn} do
      mis()

      conn
      |> put_client_id_header(UUID.generate())
      |> delete(client_connection_path(conn, :delete, UUID.generate(), UUID.generate()))
      |> json_response(403)
    end
  end

  defp connection(client_id, id) do
    %{
      "id" => id,
      "redirect_uri" => "http://example.com",
      "client_id" => client_id,
      "secret" => "some-secret",
      "consumer_id" => UUID.generate(),
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
