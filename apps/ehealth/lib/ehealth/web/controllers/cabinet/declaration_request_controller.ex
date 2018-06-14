defmodule EHealth.Web.Cabinet.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.Cabinet.DeclarationRequests

  action_fallback(EHealth.Web.FallbackController)

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, paging} <- DeclarationRequests.search(params, headers) do
      render(conn, "index.json", declaration_requests: paging.entries, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, declaration_request} <- DeclarationRequests.get_by_id(id, headers),
         urgent_data = Map.take(declaration_request, [:authentication_method_current, :documents]),
         {:ok, %{"data" => %{"hash" => hash}}} = @ops_api.get_latest_block(headers) do
      conn
      |> assign(:urgent, urgent_data)
      |> render("declaration_request.json", declaration_request: declaration_request, hash: hash)
    end
  end
end
