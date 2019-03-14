defmodule EHealth.Web.INNMController do
  @moduledoc false
  use EHealth.Web, :controller

  alias Core.Medications, as: API
  alias Core.Medications.INNM
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with %Page{} = paging <- API.list_innms(params) do
      render(conn, "index.json", innms: paging.entries, paging: paging)
    end
  end

  def create(conn, innm_params) do
    actor_id = get_consumer_id(conn.req_headers)

    with {:ok, %INNM{} = innm} <- API.create_innm(actor_id, innm_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", innm_path(conn, :show, innm))
      |> render("show.json", innm: innm)
    end
  end

  def show(conn, %{"id" => id}) do
    innm = API.get_innm!(id)
    render(conn, "show.json", innm: innm)
  end
end
