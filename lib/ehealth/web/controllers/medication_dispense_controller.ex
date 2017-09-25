defmodule EHealth.Web.MedicationDispenseController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.MedicationDispense.API
  require Logger

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, medication_dispense, references} <- API.list(params, headers) do
      render(conn, "index.json", medication_dispenses: medication_dispense, references: references)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, medication_dispense, references} <- API.get_by_id(params, headers) do
      render(conn, "show.json", medication_dispense: medication_dispense, references: references)
    end
  end

  def create(conn, params) do
    code = Map.get(params, "code")
    request_params = Map.get(params, "medication_dispense")
    with {:ok, medication_dispense, references} <- API.create(conn.req_headers, code, request_params) do
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
