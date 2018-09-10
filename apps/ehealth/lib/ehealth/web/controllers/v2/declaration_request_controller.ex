defmodule EHealth.Web.V2.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Core.DeclarationRequests
  alias EHealth.Web.DeclarationRequestView
  require Logger

  @ops_api Application.get_env(:core, :api_resolvers)[:ops]

  action_fallback(EHealth.Web.FallbackController)

  def create(%Plug.Conn{req_headers: headers} = conn, %{"declaration_request" => params}) do
    with {:ok, %{urgent_data: urgent_data, finalize: result}} <-
           DeclarationRequests.create_offline(params, headers, :v2),
         {:ok, %{"data" => %{"hash" => hash}}} = @ops_api.get_latest_block(headers) do
      conn
      |> assign(:urgent, urgent_data)
      |> render(DeclarationRequestView, "declaration_request.json", declaration_request: result, hash: hash)
    end
  end
end
