defmodule EHealth.Web.UserRoleController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.API.Mithril, as: MithrilAPI

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: headers} = conn, _params) do
    user_id = get_consumer_id(headers)
    with {:ok, roles} = MithrilAPI.get_user_roles(get_consumer_id(headers)) do
      render(conn, "index.json", roles: roles)
    end
  end
end
