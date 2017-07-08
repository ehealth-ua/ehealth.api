defmodule EHealth.Web.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.DeclarationRequest.API, as: DeclarationRequestAPI

  action_fallback EHealth.Web.FallbackController

  def show(conn, %{"id" => id}) do
    declaration_request = DeclarationRequestAPI.get_declaration_request_by_id!(id)
    render(conn, "show.json", declaration_request: declaration_request)
  end

  def create(conn, %{"declaration_request" => declaration_request}) do
    user_id = get_consumer_id(conn.req_headers)
    client_id = get_client_id(conn.req_headers)

    with {:ok, %{finalize: result}} <- DeclarationRequestAPI.create(declaration_request, user_id, client_id) do
      render(conn, "declaration_request.json", declaration_request: result)
    end
  end

  def approve(conn, %{"id" => id, "verification_code" => verification_code}) do
    user_id = get_consumer_id(conn.req_headers)

    case DeclarationRequestAPI.approve(id, verification_code, user_id) do
      {:ok, %{declaration_request: declaration_request}} ->
        render(conn, "status.json", declaration_request: declaration_request)
      {:error, :verification, error_struct, _} ->
        conn
        |> put_status(:failed_dependency)
        |> render("microservice_error.json", %{microservice_response: error_struct})
    end
  end
end
