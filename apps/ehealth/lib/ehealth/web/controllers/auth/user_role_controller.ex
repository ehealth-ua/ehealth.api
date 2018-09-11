defmodule EHealth.Web.UserRoleController do
  @moduledoc false

  use EHealth.Web, :controller

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %{"data" => roles}} <- @mithril_api.get_user_roles(get_consumer_id(headers), params, headers) do
      render(conn, "index.json", roles: roles)
    end
  end
end
