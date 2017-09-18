defmodule EHealth.Web.INNMController do
  @moduledoc false
  use EHealth.Web, :controller

  alias EHealth.PRM.Medication.API
  alias EHealth.PRM.Medication

  action_fallback EHealth.Web.FallbackController

  @innm Medication.type(:innm)

  def index(conn, _params) do
    innms = API.list_medications(@innm)
    render(conn, "index.json", innms: innms)
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
    innm = API.get_medication_by_id_and_type!(id, @innm)

    with {:ok, %Medication{} = innm} <- API.deactivate_medication(innm, conn.req_headers) do
      render(conn, "show.json", innm: innm)
    end
  end
end
