defmodule EHealth.Web.DeclarationsController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.API.OPS

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- OPS.get_declarations(params, req_headers) do
      proxy(conn, response)
    end
  end
end
