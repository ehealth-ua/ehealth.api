defmodule EHealth.Web.ServiceController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.Services
  # alias Core.Dictionaries.Dictionary

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, _) do
    render(conn, "index.json", tree: Services.list())
  end
end
