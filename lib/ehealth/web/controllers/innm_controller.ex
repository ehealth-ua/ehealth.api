defmodule EHealth.Web.INNMController do
  @moduledoc false
  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.PRM.Drugs.INNM.Schema, as: INNM
  alias EHealth.PRM.Drugs.API

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- API.list_innms(params) do
      render(conn, "index.json", innms: paging.entries, paging: paging)
    end
  end

  def create(conn, innm_params) do
    with {:ok, %INNM{} = innm} <- API.create_innm(innm_params, conn.req_headers) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", innm_path(conn, :show, innm))
      |> render("show.json", innm: innm)
    end
  end

  def show(conn, %{"id" => id}) do
    innm = API.get_innm_by_id!(id)
    render(conn, "show.json", innm: innm)
  end

  def deactivate(conn, %{"id" => id}) do
    innm = API.get_active_innm_by_id!(id)

    with {:ok, %INNM{} = innm} <- API.deactivate_medication(innm, conn.req_headers) do
      render(conn, "show.json", innm: innm)
    end
  end
end
