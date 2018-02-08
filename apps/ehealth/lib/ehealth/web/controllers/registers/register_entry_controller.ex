defmodule EHealth.Web.RegisterEntryController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Scrivener.Page
  alias EHealth.Registers.API, as: Registers

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with %Page{} = paging <- Registers.list_register_entries(params) do
      render(conn, "index.json", register_entries: paging.entries, paging: paging)
    end
  end
end
