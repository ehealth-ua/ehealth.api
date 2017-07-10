defmodule EHealth.Web.UaddressesController do
  @moduledoc false
  use EHealth.Web, :controller
  alias EHealth.Divisions.UAddress

  action_fallback EHealth.Web.FallbackController

  def update_settlements(%Plug.Conn{req_headers: req_headers} = conn, attrs) do
    with {:ok, %{settlement: %{"meta" => %{}} = response}} <- UAddress.update_settlement(attrs, req_headers) do
      proxy(conn, response)
    end
  end
end
