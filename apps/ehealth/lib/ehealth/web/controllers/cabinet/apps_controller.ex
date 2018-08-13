defmodule EHealth.Web.AppsController do
  @moduledoc false
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]
  use EHealth.Web, :controller
  alias EHealth.Web.Cabinet.AppsView

  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]

  action_fallback(EHealth.Web.FallbackController)

  def delete_by_user(%Plug.Conn{req_headers: headers} = conn, %{"user_id" => user_id}) do
    client_id = get_client_id(headers)

    with {:ok, _} <- @mithril_api.delete_apps_by_user_and_client(user_id, client_id, headers) do
      send_resp(conn, :no_content, "")
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    with {:ok, %{"data" => app}} <- @mithril_api.get_app(id, params, headers) do
      render(conn, AppsView, "app_show.json", %{app: app})
    end
  end

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %{"data" => apps}} <- @mithril_api.get_apps(params, headers) do
      render(conn, AppsView, "app_index.json", %{apps: apps})
    end
  end

  def update(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %{"data" => app}} <- @mithril_api.update_app(headers, params) do
      render(conn, AppsView, "app_show.json", %{app: app})
    end
  end

  def delete(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, _} <- @mithril_api.delete_app(id, headers) do
      send_resp(conn, :no_content, "")
    end
  end

  def refresh_secret(%Plug.Conn{req_headers: headers} = conn, %{"legal_entity_id" => client_id, "id" => id}) do
    if client_id == id do
      with {:ok, %{"data" => client}} <- @mithril_api.refresh_secret(client_id, headers) do
        render(conn, AppsView, "client.json", %{client: client})
      end
    else
      {:error, :forbidden}
    end
  end

  def refresh_secret(_, _), do: {:error, :forbidden}
end
