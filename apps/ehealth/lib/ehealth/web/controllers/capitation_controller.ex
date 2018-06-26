defmodule EHealth.Web.CapitationController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.Capitation.Capitation
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with %Page{} = paging <- Capitation.list(params, headers) do
      render(
        conn,
        "index.json",
        reports: paging.entries,
        paging: paging
      )
    end
  end
end
