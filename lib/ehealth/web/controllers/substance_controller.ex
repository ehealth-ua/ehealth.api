defmodule EHealth.Web.SubstanceController do
  @moduledoc false
  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.PRM.Medication.API
  alias EHealth.PRM.Medication.Substance

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- API.list_substances(params) do
      render(conn, "index.json", substances: paging.entries, paging: paging)
    end
  end

  def create(conn, substance_params) do
    with {:ok, %Substance{} = substance} <- API.create_substance(substance_params, conn.req_headers) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", substance_path(conn, :show, substance))
      |> render("show.json", substance: substance)
    end
  end

  def show(conn, %{"id" => id}) do
    substance = API.get_substance!(id)
    render(conn, "show.json", substance: substance)
  end
end
