defmodule EHealth.Web.GlobalParameterController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.GlobalParameters

  action_fallback EHealth.Web.FallbackController

  def index(conn, _params) do
    with global_parameters <- GlobalParameters.list() do
      render(conn, "index.json", global_parameters: global_parameters)
    end
  end

  def create_or_update(%Plug.Conn{req_headers: req_headers} = conn, params) do
    client_id = get_client_id(req_headers)

    with {:ok, global_parameters} <- GlobalParameters.create_or_update(params, client_id) do
      render(conn, "index.json", global_parameters: global_parameters)
    end
  end
end
