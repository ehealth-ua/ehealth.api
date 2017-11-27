defmodule EHealth.Web.BlackListUserController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Scrivener.Page
  alias EHealth.BlackListUsers

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- BlackListUsers.list(params) do
      render(conn, "index.json", black_list_users: paging.entries, paging: paging)
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, black_list_user} <- BlackListUsers.create(headers, params) do
      conn
      |> put_status(:created)
      |> render("show.json", black_list_user: black_list_user)
    end
  end

  def deactivate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    user_id = get_consumer_id(headers)
    black_list_user = BlackListUsers.get_by_id!(id)

    with {:ok, black_list_user} <- BlackListUsers.deactivate(user_id, black_list_user) do
      render(conn, "show.json", black_list_user: black_list_user)
    end
  end
end
