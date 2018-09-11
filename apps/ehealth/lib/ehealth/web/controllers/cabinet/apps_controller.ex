defmodule EHealth.Web.AppsController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Web.Cabinet.AppsView

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  action_fallback(EHealth.Web.FallbackController)

  def delete_by_user(%Plug.Conn{req_headers: headers} = conn, %{"user_id" => user_id}) do
    client_id = get_client_id(headers)

    with {:ok, _} <- @mithril_api.delete_apps_by_user_and_client(user_id, client_id, headers) do
      send_resp(conn, :no_content, "")
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    with {:ok, %{"data" => app}} <- @mithril_api.get_app(id, headers, params) do
      render(
        conn,
        AppsView,
        "app_show.json",
        app: app
      )
    end
  end

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %{"data" => apps, "paging" => paging}} <- @mithril_api.list_apps(params, headers) do
      paging =
        paging
        |> create_page()
        |> Map.put(:entries, apps)

      render(
        conn,
        AppsView,
        "app_index.json",
        apps: paging.entries,
        paging: paging
      )
    end
  end

  def update(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %{"data" => app}} <- @mithril_api.update_app(headers, params) do
      render(
        conn,
        AppsView,
        "app_show.json",
        app: app
      )
    end
  end

  def delete(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, _} <- @mithril_api.delete_app(id, headers) do
      send_resp(conn, :no_content, "")
    end
  end
end
