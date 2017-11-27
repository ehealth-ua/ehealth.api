defmodule EHealth.Web.PartyUserController do
  @moduledoc false
  use EHealth.Web, :controller

  alias EHealth.PartyUsers
  alias Scrivener.Page

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- PartyUsers.list(params) do
      render(conn, "index.json", party_users: paging.entries, paging: paging)
    end
  end
end
