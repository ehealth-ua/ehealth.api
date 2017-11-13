defmodule EHealth.Web.MedicationDispenseController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.MedicationDispense.API
  alias EHealth.MedicationRequests.API, as: MedicationRequests
  alias Scrivener.Page
  require Logger

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, medication_dispenses, references, paging} <- API.list(params, headers) do
      paging = Enum.map(paging, fn({key, value}) -> {String.to_atom(key), value} end)
      render(conn, "index.json",
        medication_dispenses: medication_dispenses,
        references: references,
        paging: struct(Page, paging)
      )
    end
  end

  def by_medication_request(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type
    with {:ok, _} <- MedicationRequests.get_medication_request(params, client_type, headers),
         {:ok, medication_dispenses, references} <- API.list_by_medication_request(params, headers)
    do
      render(conn, "index.json", medication_dispenses: medication_dispenses, references: references)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, medication_dispense, references} <- API.get_by_id(params, headers) do
      render(conn, "show.json", medication_dispense: medication_dispense, references: references)
    end
  end

  def create(conn, params) do
    code = Map.get(params, "code")
    client_type = conn.assigns.client_type
    with {:ok, medication_dispense, references} <- API.create(conn.req_headers, client_type, code, params) do
      conn
      |> put_status(:created)
      |> render("show.json", medication_dispense: medication_dispense, references: references)
    end
  end

  def process(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, medication_dispense, references} <- API.process(params, headers) do
      render(conn, "show.json", medication_dispense: medication_dispense, references: references)
    end
  end

  def reject(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, medication_dispense, references} <- API.reject(params, headers) do
      render(conn, "show.json", medication_dispense: medication_dispense, references: references)
    end
  end
end
