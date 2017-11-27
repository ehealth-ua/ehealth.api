defmodule EHealth.Web.INNMDosageController do
  @moduledoc false
  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.Medications.INNMDosage
  alias EHealth.Medications, as: API

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- API.list_innm_dosages(params) do
      render(conn, "index.json", innm_dosages: paging.entries, paging: paging)
    end
  end

  def create(conn, innm_dosage_params) do
    with {:ok, %INNMDosage{} = innm_dosage} <- API.create_innm_dosage(innm_dosage_params, conn.req_headers) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", innm_dosage_path(conn, :show, innm_dosage))
      |> render("show.json", innm_dosage: innm_dosage)
    end
  end

  def show(conn, %{"id" => id}) do
    innm_dosage = API.get_innm_dosage_by_id!(id)
    render(conn, "show.json", innm_dosage: innm_dosage)
  end

  def deactivate(conn, %{"id" => id}) do
    innm_dosage = API.get_innm_dosage_by_id!(id)

    with {:ok, %INNMDosage{} = innm_dosage} <- API.deactivate_innm_dosage(innm_dosage, conn.req_headers) do
      render(conn, "show.json", innm_dosage: innm_dosage)
    end
  end
end
