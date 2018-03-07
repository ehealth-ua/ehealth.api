defmodule EHealth.Web.HealthController do
  @moduledoc "Health check"
  use EHealth.Web, :controller

  def show(conn, _params), do: send_resp(conn, 200, "")
end
