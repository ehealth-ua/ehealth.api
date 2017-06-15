defmodule EHealth.Web.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.DeclarationRequest.API

  action_fallback EHealth.Web.FallbackController

  def create(conn, %{"declaration_request" => declaration_request}) do
    user_id =
      conn
      |> get_req_header("x-consumer-id")
      |> hd()

    result = API.create_declaration_request(declaration_request, user_id)

    with {:ok, %{declaration_request: declaration_request, previous_requests: _previous_requests}} <- result do
      render(conn, "show.json", declaration_request: declaration_request)
    end
  end
end
