defmodule EHealth.Web.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.DeclarationRequest.API, as: DeclarationRequestAPI

  action_fallback EHealth.Web.FallbackController

  def create(conn, %{"declaration_request" => declaration_request}) do
    user_id = get_consumer_id(conn.req_headers)
    client_id = get_client_id(conn.req_headers)

    case DeclarationRequestAPI.create(declaration_request, user_id, client_id) do
      {:ok, %{finalize: declaration_request}} ->
        render(conn, "show.json", declaration_request: declaration_request)
      {:error, _transaction_step, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(EView.Views.ValidationError, :"422", changeset)
      {:error, microservice_response} ->
        conn
        |> put_status(:failed_dependency)
        |> render("microservice_error.json", %{microservice_response: microservice_response})
    end
  end

  def approve(conn, %{"id" => id, "verification_code" => verification_code}) do
    user_id = get_consumer_id(conn.req_headers)

    case DeclarationRequestAPI.approve(id, verification_code, user_id) do
      {:ok, %{declaration_request: declaration_request}} ->
        render(conn, "status.json", declaration_request: declaration_request)
      {:error, _transaction_step, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(EView.Views.ValidationError, :"422", changeset)
    end
  end
end
