defmodule EHealth.Web.MedicationRequestController do
  @moduledoc false
  use EHealth.Web, :controller

  alias Core.MedicationRequests.API
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with %Page{entries: data} = paging <- API.list(params, client_type, headers) do
      render(conn, "index.json", medication_requests: data, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, medication_request} <- API.show(params, client_type, headers) do
      render(conn, "show.json", medication_request: medication_request)
    end
  end

  def reject(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, medication_request} <- API.reject(params, client_type, headers) do
      render(conn, "show.json", medication_request: medication_request)
    end
  end

  def resend(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, medication_request} <- API.resend(params, client_type, headers) do
      render(conn, "show.json", medication_request: medication_request)
    end
  end

  def qualify(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    client_type = conn.assigns.client_type

    with {:ok, medical_programs, validations} <- API.qualify(id, client_type, Map.delete(params, "id"), headers) do
      render(
        conn,
        "qualify.json",
        medical_programs: medical_programs,
        validations: validations
      )
    end
  end
end
