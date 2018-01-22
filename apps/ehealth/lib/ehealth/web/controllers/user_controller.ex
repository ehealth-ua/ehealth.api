defmodule EHealth.Web.UserController do
  @moduledoc false
  use EHealth.Web, :controller
  alias EHealth.Users.API

  action_fallback(EHealth.Web.FallbackController)

  def create_credentials_recovery_request(conn, %{"credentials_recovery_request" => attrs}) do
    opts = build_upstream_opts(conn)

    with {:ok, credentials_recovery_request} <- API.create_credentials_recovery_request(attrs, opts) do
      conn
      |> put_status(:created)
      |> render("credentials_recovery_request.json", credentials_recovery_request: credentials_recovery_request)
    end
  end

  def reset_password(conn, %{"id" => id, "user" => user_attrs}) do
    opts = build_upstream_opts(conn)

    with {:ok, user} <- API.reset_password(id, user_attrs, opts) do
      render(conn, "show.json", user: user)
    end
  end

  defp build_upstream_opts(conn) do
    request_id = conn |> get_resp_header("x-request-id") |> hd()
    [upstream_headers: [{"x-request-id", request_id}]]
  end
end
