defmodule EHealth.Web.UaddressesController do
  @moduledoc false
  use EHealth.Web, :controller
  alias EHealth.Divisions.UAddress

  action_fallback EHealth.Web.FallbackController

  def update_settlements(conn, %{"id" => id, "settlement" => settlement} = attrs) do
    with {:ok, %{settlement: %{"meta" => %{}} = response}} <- UAddress.update_settlement(attrs, conn.req_headers) do
      proxy(conn, response)
    end
  end
end
