defmodule EHealth.Web.INNMController do
  @moduledoc false
  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.PRM.Medication
  alias EHealth.PRM.Medication.API

  action_fallback EHealth.Web.FallbackController

  @innm Medication.type(:innm)

  def index(conn, params) do
    with %Page{} = paging <- API.list_medications(params, @innm) do
      render(conn, "index.json", innms: paging.entries, paging: paging)
    end
  end

  def create(conn, innm_params) do
    with {:ok, %Medication{} = innm} <-
           API.create_medication(innm_params, :innm, conn.req_headers) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", innm_path(conn, :show, innm))
      |> render("show.json", innm: innm)
    end
  end

  def show(conn, %{"id" => id}) do
    innm = API.get_medication_by_id_and_type!(id, @innm)
    render(conn, "show.json", innm: innm)
  end

  def deactivate(conn, %{"id" => id}) do
    innm = API.get_active_medication_by_id_and_type!(id, @innm)

    with {:ok, %Medication{} = innm} <- API.deactivate_medication(innm, conn.req_headers) do
      render(conn, "show.json", innm: innm)
    end
  end
end
