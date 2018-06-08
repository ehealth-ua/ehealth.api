defmodule EHealth.Web.Cabinet.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Cabinet.DeclarationRequests

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, paging} <- DeclarationRequests.search(params, headers) do
      render(conn, "index.json", declaration_requests: paging.entries, paging: paging)
    end
  end
end
