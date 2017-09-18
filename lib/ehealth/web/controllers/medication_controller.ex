defmodule EHealth.Web.MedicationController do
  @moduledoc false
  use EHealth.Web, :controller

  alias EHealth.PRM.Medication.API
  alias EHealth.PRM.Medication

  action_fallback EHealth.Web.FallbackController

  @medication Medication.type(:medication)

  def index(conn, _params) do
    medications = API.list_medications(@medication)
    render(conn, "index.json", medications: medications)
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
