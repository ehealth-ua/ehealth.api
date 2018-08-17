defmodule Mithril.Web.AppControllerTest do
  use EHealth.Web.ConnCase

  import Mox
  alias Ecto.UUID

  # For Mox lib. Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  defp app do
    %{
      "id" => UUID.generate(),
      "user_id" => UUID.generate(),
      "client_name" => "app",
      "client_id" => UUID.generate(),
      "scope" => "scope",
      "created_at" => DateTime.utc_now(),
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

  describe "refresh client secret" do
    test "success refresh client secret", %{conn: conn} do
      id = UUID.generate()
      msp()

      expect(MithrilMock, :refresh_secret, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "name" => "client"
           },
           "meta" => %{"code" => 200}
         }}
      end)

      conn = put_client_id_header(conn, id)

      resp =
        conn
        |> patch(apps_path(conn, :refresh_secret, id))
        |> json_response(200)

      assert %{"id" => ^id, "name" => "client"} = resp["data"]
    end

    test "failed to refresh client secret", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, apps_path(conn, :refresh_secret, Ecto.UUID.generate()))
      assert json_response(conn, 403)
    end
  end

  describe "get apps" do
    test "get app ok", %{conn: conn} do
      expect(MithrilMock, :get_app, fn _id, _params, _headers ->
        {:ok,
         %{
           "data" => app(),
           "paging" => paging()
         }}
      end)

      resp =
        conn
        |> put_req_header("x-consumer-id", UUID.generate())
        |> get(apps_path(conn, :show, UUID.generate()), %{})
        |> json_response(200)

      schema =
        "specs/json_schemas/apps/app_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "get app not found", %{conn: conn} do
      expect(MithrilMock, :get_app, fn _id, _params, _headers -> {:error, :not_found} end)

      conn
      |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
      |> get(apps_path(conn, :show, UUID.generate()), %{})
      |> json_response(404)
    end

    test "get apps ok", %{conn: conn} do
      expect(MithrilMock, :list_apps, fn _params, _headers ->
        {:ok,
         %{
           "data" => Enum.map(1..3, fn _ -> app() end),
           "paging" => paging()
         }}
      end)

      resp =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> get(apps_path(conn, :index), %{})
        |> json_response(200)

      schema =
        "specs/json_schemas/apps/apps_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "update app put ok", %{conn: conn} do
      expect(MithrilMock, :update_app, fn _params, _headers ->
        {:ok,
         %{
           "data" => app()
         }}
      end)

      resp =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put(apps_path(conn, :update, UUID.generate()), %{})
        |> json_response(200)

      schema =
        "specs/json_schemas/apps/app_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "update app patch ok", %{conn: conn} do
      expect(MithrilMock, :update_app, fn _params, _headers ->
        {:ok,
         %{
           "data" => app(),
           "paging" => paging()
         }}
      end)

      resp =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> patch(apps_path(conn, :update, UUID.generate()), %{})
        |> json_response(200)

      schema =
        "specs/json_schemas/apps/app_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "delete app by user ok", %{conn: conn} do
      expect(MithrilMock, :delete_apps_by_user_and_client, fn _user_id, _client_id, _headers ->
        {:ok, 0}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)

      resp =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> delete(apps_path(conn, :delete_by_user, user_id), %{})

      assert response(resp, 204)
    end

    test "delete app by user without scope headers", %{conn: conn} do
      user_id = UUID.generate()

      resp = delete(conn, apps_path(conn, :delete_by_user, user_id), %{})

      assert response(resp, 401)
    end

    test "delete app ok", %{conn: conn} do
      expect(MithrilMock, :delete_app, fn _params, _headers ->
        {:ok, 0}
      end)

      resp =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> delete(apps_path(conn, :delete, UUID.generate()), %{})

      assert response(resp, 204)
    end

    test "delete app do not found", %{conn: conn} do
      expect(MithrilMock, :delete_app, fn _params, _headers ->
        {:error, :not_found}
      end)

      conn
      |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
      |> delete(apps_path(conn, :delete, UUID.generate()), %{})
      |> json_response(404)
    end

    test "delete app do internal error", %{conn: conn} do
      expect(MithrilMock, :delete_app, fn _params, _headers ->
        {:error, 0}
      end)

      resp =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> delete(apps_path(conn, :delete, UUID.generate()), %{})

      assert response(resp, 501)
    end
  end
end
