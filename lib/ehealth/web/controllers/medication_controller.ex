defmodule EHealth.Web.MedicationController do
  @moduledoc false
  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.PRM.Medication
  alias EHealth.PRM.Medication.API

  action_fallback EHealth.Web.FallbackController

  @medication Medication.type(:medication)

  def index(conn, params) do
    with %Page{} = paging <- API.list_medications(params, @medication) do
      render(conn, "index.json", medications: paging.entries, paging: paging)
    end
  end

  def create(conn, medication_params) do
    with {:ok, %Medication{} = medication} <-
           API.create_medication(medication_params, :medication, conn.req_headers) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", medication_path(conn, :show, medication))
      |> render("show.json", medication: medication)
    end
  end

  def show(conn, %{"id" => id}) do
    medication = API.get_medication_by_id_and_type!(id, @medication)
    render(conn, "show.json", medication: medication)
  end

  def deactivate(conn, %{"id" => id}) do
    medication = API.get_medication_by_id_and_type!(id, @medication)

    with {:ok, %Medication{} = medication} <- API.deactivate_medication(medication, conn.req_headers) do
      render(conn, "show.json", medication: medication)
    end
  end
end
