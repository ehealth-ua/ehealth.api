defmodule EHealth.Web.MedicalProgramController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.MedicalPrograms
  alias Scrivener.Page
  require Logger

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- MedicalPrograms.list(params) do
      render(conn, "index.json", medical_programs: paging.entries, paging: paging)
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    user_id = get_consumer_id(headers)
    with {:ok, medical_program} <- MedicalPrograms.create(user_id, params) do
      conn
      |> put_status(:created)
      |> render("show.json", medical_program: medical_program)
    end
  end

  def show(conn, %{"id" => id}) do
    with medical_program <- MedicalPrograms.get_by_id!(id) do
      render(conn, "show.json", medical_program: medical_program)
    end
  end

  def deactivate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    user_id = get_consumer_id(headers)
    medical_program = MedicalPrograms.get_by_id!(id)

    with {:ok, medical_program} <- MedicalPrograms.deactivate(user_id, medical_program) do
      render(conn, "show.json", medical_program: medical_program)
    end
  end
end
