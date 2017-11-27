defmodule EHealth.Web.MedicationController do
  @moduledoc false
  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.Medications.Medication
  alias EHealth.Medications, as: API

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- API.list_medications(params) do
      render(conn, "index.json", medications: paging.entries, paging: paging)
    end
  end

  def drugs(conn, params) do
    with %Page{} = paging <- API.get_drugs(params) do
      render(conn, "drugs.json", drugs: paging.entries, paging: paging)
    end
  end

  def create(conn, medication_params) do
    with {:ok, %Medication{} = medication} <- API.create_medication(medication_params, conn.req_headers) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", medication_path(conn, :show, medication))
      |> render("show.json", medication: medication)
    end
  end

  def show(conn, %{"id" => id}) do
    medication = API.get_medication_by_id!(id)
    render(conn, "show.json", medication: medication)
  end

  def deactivate(conn, %{"id" => id}) do
    medication = API.get_medication_by_id!(id)

    with {:ok, %Medication{} = medication} <- API.deactivate_medication(medication, conn.req_headers) do
      render(conn, "show.json", medication: medication)
    end
  end
end
