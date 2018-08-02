defmodule EHealth.Web.MedicationRequestRequestController do
  @moduledoc false
  use EHealth.Web, :controller

  alias EHealth.MedicationRequestRequests, as: API
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)
  alias EHealth.Web.MedicationRequestView

  def index(conn, params) do
    with %Page{} = paging <- API.list_medication_request_requests(params, conn.req_headers) do
      render(conn, "index.json", medication_request_requests: paging.entries, paging: paging)
    end
  end

  def create(conn, %{"medication_request_request" => params}) do
    user_id = get_consumer_id(conn.req_headers)
    client_id = get_client_id(conn.req_headers)

    with {:ok, mrr} <- API.create(params, user_id, client_id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", medication_request_request_path(conn, :show, mrr.medication_request_request))
      |> render("medication_request_request_detail.json", %{data: mrr})
    end
  end

  def prequalify(conn, params) do
    user_id = get_consumer_id(conn.req_headers)
    client_id = get_client_id(conn.req_headers)

    with {:ok, programs} <- API.prequalify(params, user_id, client_id) do
      conn
      |> put_status(200)
      |> render("show_prequalify_programs.json", %{programs: programs})
    end
  end

  def reject(conn, %{"id" => id}) do
    user_id = get_consumer_id(conn.req_headers)
    client_id = get_client_id(conn.req_headers)

    with {:ok, mrr} <- API.reject(id, user_id, client_id) do
      conn
      |> put_status(200)
      |> render("medication_request_request_detail.json", %{data: mrr})
    end
  end

  def sign(conn, params) do
    with {:ok, medication_request} <- API.sign(params, conn.req_headers) do
      conn
      |> put_status(200)
      |> render(MedicationRequestView, "show.json", medication_request: medication_request)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, mrr} <- API.show(id) do
      conn
      |> put_status(200)
      |> render("medication_request_request_detail.json", data: mrr)
    end
  end
end
