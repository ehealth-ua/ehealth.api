defmodule EHealth.Web.PageController do
  @moduledoc """
  Sample controller for generated application.
  """
  use EHealth.Web, :controller

  action_fallback EHealth.Web.FallbackController

  def index(conn, _params) do
    render conn, "page.json"
  end
end
